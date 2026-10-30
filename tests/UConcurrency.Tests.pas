unit UConcurrency.Tests;

{ Copyright © 2026 Herman Schoenfeld <https://www.sphere10.com>
  Distributed under the MIT software license, see the accompanying LICENSE. }

{$MODE DELPHI}{$H+}

interface

uses Classes, SysUtils, SyncObjs, Generics.Collections, fpcunit, testregistry,
  UConcurrency;

type
  TLockAction = (laRead, laWrite, laUpgrade, laExitRead, laExitWrite,
    laExitUpgrade, laCancellableRead, laUpgradeThenWrite);

  TLockWorker = class(TThread)
  private
    FLock: TReadWriteLock;
    FAction: TLockAction;
    FTimeout: Integer;
  protected
    procedure Execute; override;
  public
    Entered, ReleaseGate, Done: TEvent;
    Acquired: Boolean;
    ErrorClass, ErrorMessage: String;
    Elapsed: UInt64;
    OwnReadCount, OwnWriteCount, OwnUpgradeCount: Integer;
    constructor Create(ALock: TReadWriteLock; AAction: TLockAction; ATimeout: Integer);
    destructor Destroy; override;
    procedure RequestStop;
  end;

  TReadWriteLockTests = class(TTestCase)
  private
    FLock: TReadWriteLock;
    FWorkers: TList<TLockWorker>;
    function Worker(AAction: TLockAction; ATimeout: Integer = 2500): TLockWorker;
    procedure Await(AEvent: TEvent; const ADescription: String);
    procedure WaitCount(AKind, ACount: Integer);
    procedure Completed(AWorker: TLockWorker);
    procedure Release(AWorker: TLockWorker);
    procedure ExpectRecursion(AAction: TLockAction);
    procedure RecursivePolicy;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DefaultPolicyAndEmptyCounts;
    procedure DifferentThreadsReadConcurrently;
    procedure WriterExcludesOtherReadersWritersAndUpgraders;
    procedure WaitingWriterPrecedesNewReader;
    procedure WaitingWriterPrecedesNewUpgrader;
    procedure RecursiveReadsCountOneReader;
    procedure RecursiveWriterCanReadWriteAndUpgrade;
    procedure NoRecursionRejectsRepeatedAcquisition;
    procedure OrdinaryReadCannotPromoteUnderEitherPolicy;
    procedure NoRecursionUpgradeableReadThenWriteIsRejected;
    procedure UpgradeableReadPromotesWithoutOtherReaders;
    procedure RecursiveUpgradeableWithExplicitReadCanPromote;
    procedure UpgradeWaitsForOtherReaderAndRetainsOwnershipOnTimeout;
    procedure WaitingUpgradePromotesWhenOtherReaderReleases;
    procedure OnlyOneUpgradeableOwnerAndReadersCanShare;
    procedure WriteToReadDowngradeRetainsReader;
    procedure UpgradeableToReadDowngradeRetainsReader;
    procedure FiniteTimeoutIsBoundedAndRemovesWaiter;
    procedure ZeroTimeoutDoesNotRegisterWaiter;
    procedure InfiniteTimeoutWakesOnRelease;
    procedure TimedOutWriterReleasesWaitingReaders;
    procedure WrongThreadCannotReleaseAnyMode;
    procedure UnmatchedReleaseDoesNotChangeOwnership;
    procedure InvalidTimeoutDoesNotAcquire;
    procedure DisposeRejectsActiveOwnershipAndCanBeRetried;
    procedure DisposeRejectsWaiterAndWaiterLaterCompletes;
    procedure DisposedLockRejectsAcquisitions;
    procedure ExceptionCleanupReleasesOnlyOwnedAcquisitions;
    procedure PromotedWriteExceptionRetainsSurroundingUpgradeableLock;
    procedure HeldAndRecursivePropertiesAreThreadSpecific;
    procedure FiniteWaitPermitsCooperativeCancellation;
  end;

implementation

function Tick: UInt64;
begin Result := GetTickCount64; end;

constructor TLockWorker.Create(ALock: TReadWriteLock; AAction: TLockAction; ATimeout: Integer);
begin
  inherited Create(True);
  FLock := ALock;
  FAction := AAction;
  FTimeout := ATimeout;
  Entered := TEvent.Create(nil, True, False, '');
  ReleaseGate := TEvent.Create(nil, True, False, '');
  Done := TEvent.Create(nil, True, False, '');
  Start;
end;

destructor TLockWorker.Destroy;
begin
  RequestStop;
  WaitFor;
  Done.Free;
  ReleaseGate.Free;
  Entered.Free;
  inherited;
end;

procedure TLockWorker.RequestStop;
begin
  Terminate;
  ReleaseGate.SetEvent;
end;

procedure TLockWorker.Execute;
var LStarted: UInt64;
begin
  LStarted := Tick;
  try
    try
      case FAction of
        laRead: Acquired := FLock.TryEnterReadLock(FTimeout);
        laWrite: Acquired := FLock.TryEnterWriteLock(FTimeout);
        laUpgrade: Acquired := FLock.TryEnterUpgradeableReadLock(FTimeout);
        laExitRead: FLock.ExitReadLock;
        laExitWrite: FLock.ExitWriteLock;
        laExitUpgrade: FLock.ExitUpgradeableReadLock;
        laCancellableRead:
          while not Terminated do
            if FLock.TryEnterReadLock(FTimeout) then begin
              FLock.ExitReadLock;
              Break;
            end;
        laUpgradeThenWrite: begin
          FLock.EnterUpgradeableReadLock;
          try
            Entered.SetEvent;
            if ReleaseGate.WaitFor(4000) <> wrSignaled then
              raise Exception.Create('Promotion start gate timed out.');
            Acquired := FLock.TryEnterWriteLock(FTimeout);
            if Acquired then FLock.ExitWriteLock;
          finally FLock.ExitUpgradeableReadLock; end;
        end;
      end;
      if Acquired and (FAction in [laRead, laWrite, laUpgrade]) then begin
        try
          OwnReadCount := FLock.RecursiveReadCount;
          OwnWriteCount := FLock.RecursiveWriteCount;
          OwnUpgradeCount := FLock.RecursiveUpgradeCount;
          Entered.SetEvent;
          if ReleaseGate.WaitFor(4000) <> wrSignaled then
            raise Exception.Create('Test release gate timed out.');
        finally
          case FAction of
            laRead: FLock.ExitReadLock;
            laWrite: FLock.ExitWriteLock;
            laUpgrade: FLock.ExitUpgradeableReadLock;
          end;
        end;
      end;
    except
      on E: Exception do begin ErrorClass := E.ClassName; ErrorMessage := E.Message; end;
    end;
  finally
    Elapsed := Tick - LStarted;
    Done.SetEvent;
  end;
end;

procedure TReadWriteLockTests.SetUp;
begin
  inherited;
  FLock := TReadWriteLock.Create;
  FWorkers := TList<TLockWorker>.Create;
end;

procedure TReadWriteLockTests.TearDown;
var LWorker: TLockWorker;
begin
  for LWorker in FWorkers do LWorker.RequestStop;
  // Release test-thread ownership before joining blocked workers after a failure.
  while FLock.IsWriteLockHeld do FLock.ExitWriteLock;
  while FLock.IsUpgradeableReadLockHeld do FLock.ExitUpgradeableReadLock;
  while FLock.IsReadLockHeld do FLock.ExitReadLock;
  for LWorker in FWorkers do LWorker.Free;
  FWorkers.Free;
  FLock.Free;
  inherited;
end;

procedure TReadWriteLockTests.RecursivePolicy;
begin
  FLock.Free;
  FLock := TReadWriteLock.Create(lrpSupportsRecursion);
end;

function TReadWriteLockTests.Worker(AAction: TLockAction; ATimeout: Integer): TLockWorker;
begin
  Result := TLockWorker.Create(FLock, AAction, ATimeout);
  FWorkers.Add(Result);
end;

procedure TReadWriteLockTests.Await(AEvent: TEvent; const ADescription: String);
begin AssertEquals(ADescription, Ord(wrSignaled), Ord(AEvent.WaitFor(3000))); end;

procedure TReadWriteLockTests.WaitCount(AKind, ACount: Integer);
var LStarted: UInt64; LCount: Integer;
begin
  LStarted := Tick;
  repeat
    case AKind of
      0: LCount := FLock.WaitingReadCount;
      1: LCount := FLock.WaitingWriteCount;
    else LCount := FLock.WaitingUpgradeCount;
    end;
    if LCount = ACount then Exit;
    Sleep(1);
  until Tick - LStarted >= 2000;
  AssertEquals('Actual registered waiter count', ACount, LCount);
end;

procedure TReadWriteLockTests.Completed(AWorker: TLockWorker);
begin
  Await(AWorker.Done, 'Worker completed');
  AssertEquals(AWorker.ErrorMessage, '', AWorker.ErrorClass);
end;

procedure TReadWriteLockTests.Release(AWorker: TLockWorker);
begin
  AWorker.ReleaseGate.SetEvent;
  Completed(AWorker);
end;

procedure TReadWriteLockTests.ExpectRecursion(AAction: TLockAction);
begin
  try
    case AAction of
      laRead: FLock.TryEnterReadLock(0);
      laWrite: FLock.TryEnterWriteLock(0);
      laUpgrade: FLock.TryEnterUpgradeableReadLock(0);
    end;
    Fail('This recursion/promotion should be rejected.');
  except on E: ELockRecursionException do ; end;
end;

procedure TReadWriteLockTests.DefaultPolicyAndEmptyCounts;
begin
  AssertEquals(Ord(lrpNoRecursion), Ord(FLock.RecursionPolicy));
  AssertFalse(FLock.IsReadLockHeld or FLock.IsWriteLockHeld or FLock.IsUpgradeableReadLockHeld);
  AssertEquals(0, FLock.CurrentReadCount);
  AssertEquals(0, FLock.WaitingReadCount + FLock.WaitingWriteCount + FLock.WaitingUpgradeCount);
end;

procedure TReadWriteLockTests.DifferentThreadsReadConcurrently;
var LReader: TLockWorker;
begin
  FLock.EnterReadLock;
  LReader := Worker(laRead);
  Await(LReader.Entered, 'Second reader acquires while first still owns');
  AssertEquals(2, FLock.CurrentReadCount);
  AssertEquals(1, FLock.RecursiveReadCount);
  FLock.ExitReadLock;
  Release(LReader);
  AssertEquals(0, FLock.CurrentReadCount);
end;

procedure TReadWriteLockTests.WriterExcludesOtherReadersWritersAndUpgraders;
var LAction: TLockAction; LWorker: TLockWorker;
begin
  FLock.EnterWriteLock;
  for LAction := laRead to laUpgrade do begin
    LWorker := Worker(LAction, 0);
    Completed(LWorker);
    AssertFalse('Writer excludes other owners', LWorker.Acquired);
  end;
  AssertTrue(FLock.IsWriteLockHeld);
  AssertEquals(0, FLock.WaitingReadCount + FLock.WaitingWriteCount + FLock.WaitingUpgradeCount);
  FLock.ExitWriteLock;
end;

procedure TReadWriteLockTests.WaitingWriterPrecedesNewReader;
var LWriter, LReader: TLockWorker;
begin
  FLock.EnterReadLock;
  LWriter := Worker(laWrite);
  WaitCount(1, 1);
  LReader := Worker(laRead);
  WaitCount(0, 1);
  FLock.ExitReadLock;
  Await(LWriter.Entered, 'Waiting writer wins admission');
  AssertEquals(Ord(wrTimeout), Ord(LReader.Entered.WaitFor(0)));
  Release(LWriter);
  Await(LReader.Entered, 'Reader follows completed writer');
  Release(LReader);
end;

procedure TReadWriteLockTests.WaitingWriterPrecedesNewUpgrader;
var LWriter, LUpgrade: TLockWorker;
begin
  FLock.EnterReadLock;
  LWriter := Worker(laWrite);
  WaitCount(1, 1);
  LUpgrade := Worker(laUpgrade);
  WaitCount(2, 1);
  FLock.ExitReadLock;
  Await(LWriter.Entered, 'Writer precedes new upgrader');
  AssertEquals(Ord(wrTimeout), Ord(LUpgrade.Entered.WaitFor(0)));
  Release(LWriter);
  Await(LUpgrade.Entered, 'Upgrader follows writer');
  Release(LUpgrade);
end;

procedure TReadWriteLockTests.RecursiveReadsCountOneReader;
begin
  RecursivePolicy;
  FLock.EnterReadLock;
  FLock.EnterReadLock;
  AssertEquals(2, FLock.RecursiveReadCount);
  AssertEquals(1, FLock.CurrentReadCount);
  FLock.ExitReadLock;
  AssertTrue(FLock.IsReadLockHeld);
  FLock.ExitReadLock;
  AssertEquals(0, FLock.CurrentReadCount);
end;

procedure TReadWriteLockTests.RecursiveWriterCanReadWriteAndUpgrade;
begin
  RecursivePolicy;
  FLock.EnterWriteLock;
  FLock.EnterReadLock;
  FLock.EnterWriteLock;
  FLock.EnterUpgradeableReadLock;
  FLock.EnterUpgradeableReadLock;
  AssertEquals(2, FLock.RecursiveWriteCount);
  AssertEquals(1, FLock.RecursiveReadCount);
  AssertEquals(2, FLock.RecursiveUpgradeCount);
  FLock.ExitWriteLock;
  AssertTrue(FLock.IsWriteLockHeld);
  FLock.ExitReadLock;
  FLock.ExitUpgradeableReadLock;
  FLock.ExitWriteLock;
  AssertTrue(FLock.IsUpgradeableReadLockHeld);
  FLock.ExitUpgradeableReadLock;
end;

procedure TReadWriteLockTests.NoRecursionRejectsRepeatedAcquisition;
begin
  FLock.EnterReadLock;
  ExpectRecursion(laRead);
  AssertEquals(1, FLock.RecursiveReadCount);
  FLock.ExitReadLock;
  FLock.EnterWriteLock;
  ExpectRecursion(laWrite);
  ExpectRecursion(laRead);
  ExpectRecursion(laUpgrade);
  AssertEquals(1, FLock.RecursiveWriteCount);
  FLock.ExitWriteLock;
  FLock.EnterUpgradeableReadLock;
  ExpectRecursion(laUpgrade);
  AssertEquals(1, FLock.RecursiveUpgradeCount);
  FLock.ExitUpgradeableReadLock;
end;

procedure TReadWriteLockTests.OrdinaryReadCannotPromoteUnderEitherPolicy;
var LPolicy: TLockRecursionPolicy;
begin
  for LPolicy := lrpNoRecursion to lrpSupportsRecursion do begin
    FLock.Free;
    FLock := TReadWriteLock.Create(LPolicy);
    FLock.EnterReadLock;
    ExpectRecursion(laWrite);
    ExpectRecursion(laUpgrade);
    AssertEquals(1, FLock.RecursiveReadCount);
    FLock.ExitReadLock;
  end;
end;

procedure TReadWriteLockTests.NoRecursionUpgradeableReadThenWriteIsRejected;
begin
  FLock.EnterUpgradeableReadLock;
  FLock.EnterReadLock;
  ExpectRecursion(laWrite);
  FLock.ExitReadLock;
  AssertTrue(FLock.TryEnterWriteLock(0));
  FLock.ExitWriteLock;
  FLock.ExitUpgradeableReadLock;
end;

procedure TReadWriteLockTests.UpgradeableReadPromotesWithoutOtherReaders;
begin
  FLock.EnterUpgradeableReadLock;
  AssertEquals(0, FLock.CurrentReadCount);
  AssertTrue(FLock.TryEnterWriteLock(0));
  AssertTrue(FLock.IsWriteLockHeld and FLock.IsUpgradeableReadLockHeld);
  FLock.ExitWriteLock;
  AssertTrue(FLock.IsUpgradeableReadLockHeld);
  FLock.ExitUpgradeableReadLock;
end;

procedure TReadWriteLockTests.RecursiveUpgradeableWithExplicitReadCanPromote;
begin
  RecursivePolicy;
  FLock.EnterUpgradeableReadLock;
  FLock.EnterReadLock;
  AssertTrue(FLock.TryEnterWriteLock(0));
  FLock.ExitUpgradeableReadLock;
  AssertTrue(FLock.IsWriteLockHeld and FLock.IsReadLockHeld);
  FLock.ExitReadLock;
  FLock.ExitWriteLock;
end;

procedure TReadWriteLockTests.UpgradeWaitsForOtherReaderAndRetainsOwnershipOnTimeout;
var LReader: TLockWorker;
begin
  FLock.EnterUpgradeableReadLock;
  LReader := Worker(laRead);
  Await(LReader.Entered, 'Reader shares upgradeable ownership');
  AssertFalse(FLock.TryEnterWriteLock(70));
  AssertTrue(FLock.IsUpgradeableReadLockHeld);
  AssertFalse(FLock.IsWriteLockHeld);
  AssertEquals(0, FLock.WaitingWriteCount);
  Release(LReader);
  AssertTrue(FLock.TryEnterWriteLock(2000));
  FLock.ExitWriteLock;
  FLock.ExitUpgradeableReadLock;
end;

procedure TReadWriteLockTests.OnlyOneUpgradeableOwnerAndReadersCanShare;
var LUpgrade, LReader: TLockWorker;
begin
  FLock.EnterUpgradeableReadLock;
  LUpgrade := Worker(laUpgrade, 60);
  LReader := Worker(laRead);
  Await(LReader.Entered, 'Reader shares first upgrader');
  Completed(LUpgrade);
  AssertFalse(LUpgrade.Acquired);
  Release(LReader);
  FLock.ExitUpgradeableReadLock;
end;

procedure TReadWriteLockTests.WaitingUpgradePromotesWhenOtherReaderReleases;
var LUpgrade, LReader: TLockWorker;
begin
  FLock.EnterReadLock;
  LUpgrade := Worker(laUpgradeThenWrite);
  Await(LUpgrade.Entered, 'Upgradeable read shares existing reader');
  LUpgrade.ReleaseGate.SetEvent;
  WaitCount(1, 1);
  LReader := Worker(laRead);
  WaitCount(0, 1);
  AssertEquals(Ord(wrTimeout), Ord(LUpgrade.Done.WaitFor(0)));
  FLock.ExitReadLock;
  Completed(LUpgrade);
  AssertTrue('Pending promotion succeeds after last other reader exits', LUpgrade.Acquired);
  Await(LReader.Entered, 'New reader follows completed promotion');
  Release(LReader);
end;

procedure TReadWriteLockTests.WriteToReadDowngradeRetainsReader;
var LWriter, LReader: TLockWorker;
begin
  RecursivePolicy;
  FLock.EnterWriteLock;
  FLock.EnterReadLock;
  FLock.ExitWriteLock;
  AssertTrue(FLock.IsReadLockHeld);
  LWriter := Worker(laWrite, 0);
  Completed(LWriter);
  AssertFalse(LWriter.Acquired);
  LReader := Worker(laRead);
  Await(LReader.Entered, 'Downgrade permits another reader');
  Release(LReader);
  FLock.ExitReadLock;
end;

procedure TReadWriteLockTests.UpgradeableToReadDowngradeRetainsReader;
begin
  FLock.EnterUpgradeableReadLock;
  FLock.EnterReadLock;
  FLock.ExitUpgradeableReadLock;
  AssertTrue(FLock.IsReadLockHeld);
  ExpectRecursion(laUpgrade);
  FLock.ExitReadLock;
end;

procedure TReadWriteLockTests.FiniteTimeoutIsBoundedAndRemovesWaiter;
var LReader: TLockWorker;
begin
  FLock.EnterWriteLock;
  LReader := Worker(laRead, 90);
  Completed(LReader);
  AssertFalse(LReader.Acquired);
  AssertTrue('Actually waited', LReader.Elapsed >= 75);
  AssertTrue('Bounded timeout', LReader.Elapsed < 1000);
  AssertEquals(0, FLock.WaitingReadCount);
  FLock.ExitWriteLock;
end;

procedure TReadWriteLockTests.ZeroTimeoutDoesNotRegisterWaiter;
var LWorker: TLockWorker;
begin
  FLock.EnterReadLock;
  LWorker := Worker(laWrite, 0);
  Completed(LWorker);
  AssertFalse(LWorker.Acquired);
  AssertTrue(LWorker.Elapsed < 500);
  AssertEquals(0, FLock.WaitingWriteCount);
  FLock.ExitReadLock;
end;

procedure TReadWriteLockTests.InfiniteTimeoutWakesOnRelease;
var LReader: TLockWorker;
begin
  FLock.EnterWriteLock;
  LReader := Worker(laRead, -1);
  WaitCount(0, 1);
  AssertEquals(Ord(wrTimeout), Ord(LReader.Done.WaitFor(0)));
  FLock.ExitWriteLock;
  Await(LReader.Entered, 'Infinite waiter wakes on release');
  Release(LReader);
end;

procedure TReadWriteLockTests.TimedOutWriterReleasesWaitingReaders;
var LWriter, LReader: TLockWorker;
begin
  FLock.EnterReadLock;
  LWriter := Worker(laWrite, 160);
  WaitCount(1, 1);
  LReader := Worker(laRead);
  WaitCount(0, 1);
  Completed(LWriter);
  AssertFalse(LWriter.Acquired);
  Await(LReader.Entered, 'Writer timeout releases reader while original read remains held');
  AssertTrue(FLock.IsReadLockHeld);
  Release(LReader);
  FLock.ExitReadLock;
end;

procedure TReadWriteLockTests.WrongThreadCannotReleaseAnyMode;
var LAction: TLockAction; LWorker: TLockWorker;
begin
  for LAction := laExitRead to laExitUpgrade do begin
    case LAction of
      laExitRead: FLock.EnterReadLock;
      laExitWrite: FLock.EnterWriteLock;
      laExitUpgrade: FLock.EnterUpgradeableReadLock;
    end;
    LWorker := Worker(LAction);
    Await(LWorker.Done, 'Wrong-thread release completed');
    AssertEquals('ESynchronizationLockException', LWorker.ErrorClass);
    case LAction of
      laExitRead: begin AssertTrue(FLock.IsReadLockHeld); FLock.ExitReadLock; end;
      laExitWrite: begin AssertTrue(FLock.IsWriteLockHeld); FLock.ExitWriteLock; end;
      laExitUpgrade: begin AssertTrue(FLock.IsUpgradeableReadLockHeld); FLock.ExitUpgradeableReadLock; end;
    end;
  end;
end;

procedure TReadWriteLockTests.UnmatchedReleaseDoesNotChangeOwnership;
begin
  FLock.EnterReadLock;
  try FLock.ExitWriteLock; Fail('Unmatched release');
  except on E: ESynchronizationLockException do ; end;
  AssertTrue(FLock.IsReadLockHeld);
  FLock.ExitReadLock;
  try FLock.ExitReadLock; Fail('Extra release');
  except on E: ESynchronizationLockException do ; end;
  AssertEquals(0, FLock.CurrentReadCount);
end;

procedure TReadWriteLockTests.InvalidTimeoutDoesNotAcquire;
begin
  try FLock.TryEnterReadLock(-2); Fail('Invalid read timeout');
  except on E: EArgumentOutOfRangeException do ; end;
  try FLock.TryEnterWriteLock(-2); Fail('Invalid write timeout');
  except on E: EArgumentOutOfRangeException do ; end;
  try FLock.TryEnterUpgradeableReadLock(-2); Fail('Invalid upgrade timeout');
  except on E: EArgumentOutOfRangeException do ; end;
  AssertEquals(0, FLock.CurrentReadCount);
end;

procedure TReadWriteLockTests.DisposeRejectsActiveOwnershipAndCanBeRetried;
begin
  FLock.EnterReadLock;
  try FLock.Dispose; Fail('Dispose with owner');
  except on E: ESynchronizationLockException do ; end;
  AssertTrue(FLock.IsReadLockHeld);
  FLock.ExitReadLock;
  FLock.Dispose;
  FLock.Dispose;
  try FLock.EnterReadLock; Fail('Disposed acquisition');
  except on E: ELockDisposedException do ; end;
end;

procedure TReadWriteLockTests.DisposeRejectsWaiterAndWaiterLaterCompletes;
var LWriter: TLockWorker;
begin
  FLock.EnterReadLock;
  LWriter := Worker(laWrite);
  WaitCount(1, 1);
  try FLock.Dispose; Fail('Dispose with waiter');
  except on E: ESynchronizationLockException do ; end;
  AssertEquals(1, FLock.WaitingWriteCount);
  FLock.ExitReadLock;
  Await(LWriter.Entered, 'Rejected dispose leaves waiter usable');
  Release(LWriter);
  FLock.Dispose;
end;

procedure TReadWriteLockTests.DisposedLockRejectsAcquisitions;
begin
  FLock.Dispose;
  try FLock.EnterReadLock; Fail('Disposed read');
  except on E: ELockDisposedException do ; end;
  try FLock.EnterWriteLock; Fail('Disposed write');
  except on E: ELockDisposedException do ; end;
  try FLock.EnterUpgradeableReadLock; Fail('Disposed upgrade');
  except on E: ELockDisposedException do ; end;
end;

procedure TReadWriteLockTests.ExceptionCleanupReleasesOnlyOwnedAcquisitions;
var LWriter: TLockWorker;
begin
  RecursivePolicy;
  FLock.EnterWriteLock;
  try
    try
      FLock.EnterWriteLock;
      try
        FLock.EnterReadLock;
        try raise EAbort.Create('Expected protected work failure');
        finally FLock.ExitReadLock; end;
      finally FLock.ExitWriteLock; end;
    except on E: EAbort do ; end;
    AssertTrue(FLock.IsWriteLockHeld);
    AssertEquals(1, FLock.RecursiveWriteCount);
  finally FLock.ExitWriteLock; end;
  LWriter := Worker(laWrite);
  Await(LWriter.Entered, 'Exception cleanup released ownership');
  Release(LWriter);
end;

procedure TReadWriteLockTests.HeldAndRecursivePropertiesAreThreadSpecific;
var LReader: TLockWorker;
begin
  RecursivePolicy;
  FLock.EnterUpgradeableReadLock;
  FLock.EnterUpgradeableReadLock;
  LReader := Worker(laRead);
  Await(LReader.Entered, 'Independent reader');
  AssertEquals(1, LReader.OwnReadCount);
  AssertEquals(0, LReader.OwnWriteCount);
  AssertEquals(0, LReader.OwnUpgradeCount);
  AssertFalse(FLock.IsReadLockHeld);
  AssertEquals(2, FLock.RecursiveUpgradeCount);
  Release(LReader);
  FLock.ExitUpgradeableReadLock;
  FLock.ExitUpgradeableReadLock;
end;

procedure TReadWriteLockTests.FiniteWaitPermitsCooperativeCancellation;
var LReader: TLockWorker; LStarted: UInt64;
begin
  FLock.EnterWriteLock;
  LReader := Worker(laCancellableRead, 35);
  WaitCount(0, 1);
  LStarted := Tick;
  LReader.RequestStop;
  Completed(LReader);
  AssertTrue('Cooperative stop completes after finite wait', Tick - LStarted < 700);
  AssertTrue('Cancellation retains owner', FLock.IsWriteLockHeld);
  FLock.ExitWriteLock;
end;

procedure TReadWriteLockTests.PromotedWriteExceptionRetainsSurroundingUpgradeableLock;
var LWriter, LReader: TLockWorker;
begin
  FLock.EnterUpgradeableReadLock;
  try
    try
      FLock.EnterWriteLock;
      try
        raise EAbort.Create('Expected promoted-write failure');
      finally
        FLock.ExitWriteLock;
      end;
    except on E: EAbort do ; end;
    AssertFalse('Only write ownership was released', FLock.IsWriteLockHeld);
    AssertTrue('Surrounding upgradeable ownership survives', FLock.IsUpgradeableReadLockHeld);
    AssertEquals(1, FLock.RecursiveUpgradeCount);
    LWriter := Worker(laWrite, 0);
    Completed(LWriter);
    AssertFalse('The remaining upgrader excludes another writer', LWriter.Acquired);
    LReader := Worker(laRead);
    Await(LReader.Entered, 'Readers can share the remaining upgradeable lock');
    Release(LReader);
  finally
    FLock.ExitUpgradeableReadLock;
  end;
  LWriter := Worker(laWrite);
  Await(LWriter.Entered, 'Final typed exit releases the surrounding ownership');
  Release(LWriter);
end;

initialization
  RegisterTest(TReadWriteLockTests);
end.

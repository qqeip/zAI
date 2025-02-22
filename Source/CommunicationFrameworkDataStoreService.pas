{ ****************************************************************************** }
{ * DataStore Service                                                          * }
{ * written by QQ 600585@qq.com                                                * }
{ * https://zpascal.net                                                        * }
{ * https://github.com/PassByYou888/zAI                                        * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/PascalString                               * }
{ * https://github.com/PassByYou888/zRasterization                             * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zChinese                                   * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zGameWare                                  * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ * https://github.com/PassByYou888/FFMPEG-Header                              * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/InfiniteIoT                                * }
{ * https://github.com/PassByYou888/FastMD5                                    * }
{ ****************************************************************************** }
(*
  update history
*)

unit CommunicationFrameworkDataStoreService;

{$INCLUDE zDefine.inc}

interface


uses CoreClasses, ListEngine, UnicodeMixedLib, DataFrameEngine, MemoryStream64, CommunicationFramework, TextDataEngine,
  DoStatusIO, Cadencer, NotifyObjectBase, PascalStrings, CoreCipher, ZDBEngine, ItemStream, CoreCompress,
{$IFNDEF FPC}
  SysUtils, ZS_JsonDataObjects,
{$ENDIF}
  CommunicationFrameworkDoubleTunnelIO, CommunicationFrameworkDataStoreServiceCommon, ZDBLocalManager;

type
  TDataStoreService = class;
  TDataStoreService_PeerClientSendTunnel = class;

  TDataStoreService_PeerClientRecvTunnel = class(TPeerClientUserDefineForRecvTunnel)
  private
    FPostPerformaceCounter: Integer;
    FLastPostPerformaceTime: TTimeTick;
    FPostCounterOfPerSec: Double;
  private
    // data security
    FDataStoreCipherSecurity: TCipherSecurity;
    FDataStoreCipherKey: TCipherKeyBuffer;
  public
    constructor Create(AOwner: TPeerIO); override;
    destructor Destroy; override;

    procedure Progress; override;

    function SendTunnelDefine: TDataStoreService_PeerClientSendTunnel;
    property PostCounterOfPerSec: Double read FPostCounterOfPerSec;

    // data security
    procedure EncryptBuffer(sour: Pointer; Size: NativeInt; Encrypt: Boolean);
  end;

  TDataStoreService_PeerClientSendTunnel = class(TPeerClientUserDefineForSendTunnel)
  public
    constructor Create(AOwner: TPeerIO); override;
    destructor Destroy; override;

    function RecvTunnelDefine: TDataStoreService_PeerClientRecvTunnel;
  end;

  TDataStoreService = class(TCommunicationFramework_DoubleTunnelService, IZDBLocalManagerNotify)
  private type
    POnStorePosTransformTrigger = ^TOnStorePosTransformTrigger;

    TOnStorePosTransformTrigger = record
      Client_SendTunnel_ID: Cardinal;
      BackcallPtr: UInt64;
    end;
  private
    FZDBLocal: TZDBLocalManager;
    FQueryCallPool: THashObjectList;
    FPerQueryPipelineDelayFreeTime: Double;
  protected
    // interface from IZDBLocalManagerNotify
    procedure CreateQuery(pipe: TZDBPipeline); virtual;
    procedure QueryFragmentData(pipe: TZDBPipeline; FragmentSource: TMemoryStream64); virtual;
    procedure QueryDone(pipe: TZDBPipeline); virtual;
    procedure StorePosTransform(const Data: Pointer; const TransformBuff: PZDBStorePosTransformArray);
    procedure CreateDB(ActiveDB: TZDBStoreEngine); virtual;
    procedure CloseDB(ActiveDB: TZDBStoreEngine); virtual;
    procedure InsertData(Sender: TZDBStoreEngine; InsertPos: Int64; buff: TCoreClassStream; ID: Cardinal; CompletePos: Int64); virtual;
    procedure AddData(Sender: TZDBStoreEngine; buff: TCoreClassStream; ID: Cardinal; CompletePos: Int64); virtual;
    procedure ModifyData(Sender: TZDBStoreEngine; const StorePos: Int64; buff: TCoreClassStream); virtual;
    procedure DeleteData(Sender: TZDBStoreEngine; const StorePos: Int64); virtual;
  protected
    procedure DownloadQueryFilterMethod(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
    procedure DownloadQueryWithIDFilterMethod(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);

    procedure UserOut(UserDefineIO: TPeerClientUserDefineForRecvTunnel); override;
    procedure UserLinkSuccess(UserDefineIO: TPeerClientUserDefineForRecvTunnel); override;

    procedure Command_InitDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CloseDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_CopyDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompressDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_ReplaceDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_ResetData(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_QueryDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_DownloadDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_DownloadDBWithID(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_RequestDownloadAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_RequestFastDownloadAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_FastPostCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
    procedure Command_FastInsertCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
    procedure Command_FastModifyCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);

    procedure Command_CompletedPostAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedInsertAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedModifyAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_DeleteData(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_GetDBList(Sender: TPeerIO; InData, OutData: TDataFrameEngine); virtual;
    procedure Command_GetQueryList(Sender: TPeerIO; InData, OutData: TDataFrameEngine); virtual;
    procedure Command_GetQueryState(Sender: TPeerIO; InData, OutData: TDataFrameEngine); virtual;
    procedure Command_QueryStop(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_QueryPause(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_QueryPlay(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    // send client command
    procedure Send_CompletedFragmentBigStream(pipe: TTDataStoreService_DBPipeline);
    procedure Send_CompletedQuery(pipe: TTDataStoreService_DBPipeline);
    procedure Send_CompletedDownloadAssemble(ASendCli: TPeerIO; dbN: SystemString; dStorePos: Int64; BackcallPtr: UInt64);
    procedure Send_CompletedFastDownloadAssemble(ASendCli: TPeerIO; dbN: SystemString; dStorePos: Int64; BackcallPtr: UInt64);
    procedure Send_CompletedStorePosTransform(ASendCli: TPeerIO; const BackcallPtr: UInt64; const TransformBuff: PZDBStorePosTransformArray);
  public
    constructor Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkServer);
    destructor Destroy; override;

    procedure RegisterCommand; override;
    procedure UnRegisterCommand; override;

    procedure Progress; override;
    procedure CadencerProgress(Sender: TObject; const deltaTime, newTime: Double); override;

    function GetDataStoreUserDefine(RecvCli: TPeerIO): TDataStoreService_PeerClientRecvTunnel;

    function RegisterQueryCall(cName: SystemString): TTDataStoreService_QueryCall;
    procedure UnRegisterQueryCall(cName: SystemString);
    function GetRegistedQueryCall(cName: SystemString): TTDataStoreService_QueryCall;

    function PostCounterOfPerSec: Double;

    property ZDBLocal: TZDBLocalManager read FZDBLocal;
    property QueryCallPool: THashObjectList read FQueryCallPool;
    property PerQueryPipelineDelayFreeTime: Double read FPerQueryPipelineDelayFreeTime write FPerQueryPipelineDelayFreeTime;
  end;

  TDataStoreClient = class(TCommunicationFramework_DoubleTunnelClient)
  private
    FDataStoreCipherSecurity: TCipherSecurity;
    FDataStoreCipherKey: TCipherKeyBuffer;
    procedure EncryptBuffer(sour: Pointer; Size: NativeInt; Encrypt: Boolean);
    procedure Command_DataStoreSecurity(Sender: TPeerIO; InData: TDataFrameEngine);
  private
    procedure Command_CompletedFragmentBigStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedQuery(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedDownloadAssemble(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedFastDownloadAssemble(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedStorePosTransform(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
  public
    constructor Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkClient);
    destructor Destroy; override;

    procedure RegisterCommand; override;
    procedure UnRegisterCommand; override;

    procedure Progress; override;

    function DataCipherKeyFinished: Boolean;

    procedure InitDB(InMem: Boolean; dbN: SystemString); virtual;
    procedure CloseDB(dbN: SystemString; CloseAndDeleted: Boolean); virtual;

    procedure CopyDB(dbN, copyToN: SystemString); overload;
    procedure CopyDB(dbN, copyToN: SystemString; const BackcallPtr: PStorePosTransformNotify); overload;
    procedure CopyDB_C(dbN, copyToN: SystemString; const OnDoneCall: TStorePosTransformNotifyCall); overload;
    procedure CopyDB_M(dbN, copyToN: SystemString; const OnDoneMethod: TStorePosTransformNotifyMethod); overload;
{$IFNDEF FPC} procedure CopyDB_P(dbN, copyToN: SystemString; const OnDoneProc: TStorePosTransformNotifyProc); overload; {$ENDIF FPC}
    //
    procedure CompressDB(dbN: SystemString); overload;
    procedure CompressDB(dbN: SystemString; const BackcallPtr: PStorePosTransformNotify); overload;
    procedure CompressDB_C(dbN: SystemString; const OnDoneCall: TStorePosTransformNotifyCall); overload;
    procedure CompressDB_M(dbN: SystemString; const OnDoneMethod: TStorePosTransformNotifyMethod); overload;
{$IFNDEF FPC} procedure CompressDB_P(dbN: SystemString; const OnDoneProc: TStorePosTransformNotifyProc); overload; {$ENDIF FPC}
    //
    procedure ReplaceDB(dbN, replaceN: SystemString); virtual;
    procedure ResetData(dbN: SystemString); virtual;

    procedure QuietQueryDB(RegistedQueryName: SystemString; ReverseQuery: Boolean; dbN, outDBN: SystemString; MaxWait: Double; MaxQueryResult: Int64); virtual;

    procedure QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64; BackcallPtr: PDataStoreClientQueryNotify; RemoteParams: THashVariantList); overload; virtual;

    procedure QueryDBC(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList; // service ref remote parameter
      OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall); overload;

    procedure QueryDBC(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList;                                           // service ref remote parameter
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnQueryCall: TUserFillQueryDataCall; OnDoneCall: TUserQueryDoneNotifyCall); overload;

    procedure QueryDBM(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList; // service ref remote parameter
      OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod); overload;

    procedure QueryDBM(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList;                                           // service ref remote parameter
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnQueryMethod: TUserFillQueryDataMethod; OnDoneMethod: TUserQueryDoneNotifyMethod); overload;

{$IFNDEF FPC}
    procedure QueryDBP(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList; // service ref remote parameter
      OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc); overload;

    procedure QueryDBP(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList;                                           // service ref remote parameter
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnQueryProc: TUserFillQueryDataProc; OnDoneProc: TUserQueryDoneNotifyProc); overload;
{$ENDIF}
    //
    //
    procedure QueryDBC(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall); overload;
    procedure QueryDBM(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod); overload;
{$IFNDEF FPC} procedure QueryDBP(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc); overload; {$ENDIF}
    //
    //
    procedure DownloadDB(ReverseQuery: Boolean; dbN: SystemString; BackcallPtr: PDataStoreClientQueryNotify); overload; virtual;
    procedure DownloadDBC(ReverseQuery: Boolean; dbN: SystemString; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall); overload;
    procedure DownloadDBM(ReverseQuery: Boolean; dbN: SystemString; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod); overload;
{$IFNDEF FPC} procedure DownloadDBP(ReverseQuery: Boolean; dbN: SystemString; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc); overload; {$ENDIF}
    //
    procedure DownloadDBWithID(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; BackcallPtr: PDataStoreClientQueryNotify); overload; virtual;
    procedure DownloadDBWithIDC(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall); overload;
    procedure DownloadDBWithIDM(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod); overload;
{$IFNDEF FPC} procedure DownloadDBWithIDP(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc); overload; {$ENDIF}
    //
    procedure BeginAssembleStream; virtual;

    procedure RequestDownloadAssembleStream(dbN: SystemString; StorePos: Int64; BackcallPtr: PDataStoreClientDownloadNotify); virtual;
    procedure DownloadAssembleStreamC(dbN: SystemString; StorePos: Int64; OnDoneCall: TDownloadDoneNotifyCall); overload;
    procedure DownloadAssembleStreamM(dbN: SystemString; StorePos: Int64; OnDoneMethod: TDownloadDoneNotifyMethod); overload;
{$IFNDEF FPC} procedure DownloadAssembleStreamP(dbN: SystemString; StorePos: Int64; OnDoneProc: TDownloadDoneNotifyProc); overload; {$ENDIF}
    procedure DownloadAssembleStreamC(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneCall: TUserDownloadDoneNotifyCall); overload;
    procedure DownloadAssembleStreamM(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneMethod: TUserDownloadDoneNotifyMethod); overload;
{$IFNDEF FPC}
    procedure DownloadAssembleStreamP(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneProc: TUserDownloadDoneNotifyProc); overload;
{$ENDIF}
    //
    //
    procedure RequestFastDownloadAssembleStream(dbN: SystemString; StorePos: Int64; BackcallPtr: PDataStoreClientDownloadNotify); virtual;
    procedure FastDownloadAssembleStreamC(dbN: SystemString; StorePos: Int64; OnDoneCall: TDownloadDoneNotifyCall); overload;
    procedure FastDownloadAssembleStreamM(dbN: SystemString; StorePos: Int64; OnDoneMethod: TDownloadDoneNotifyMethod); overload;
{$IFNDEF FPC}
    procedure FastDownloadAssembleStreamP(dbN: SystemString; StorePos: Int64; OnDoneProc: TDownloadDoneNotifyProc); overload;
{$ENDIF}
    procedure FastDownloadAssembleStreamC(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneCall: TUserDownloadDoneNotifyCall); overload;
    procedure FastDownloadAssembleStreamM(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneMethod: TUserDownloadDoneNotifyMethod); overload;
{$IFNDEF FPC}
    procedure FastDownloadAssembleStreamP(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneProc: TUserDownloadDoneNotifyProc); overload;
{$ENDIF}
    //
    // Security post support
    procedure PostAssembleStream(dbN: SystemString; stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean); overload; virtual;
    procedure PostAssembleStreamCopy(dbN: SystemString; stream: TCoreClassStream; dID: Cardinal);
    procedure PostAssembleStream(dbN: SystemString; DataSource: TDataFrameEngine); overload;
    procedure PostAssembleStream(dbN: SystemString; DataSource: THashVariantList); overload;
    procedure PostAssembleStream(dbN: SystemString; DataSource: THashStringList); overload;
    procedure PostAssembleStream(dbN: SystemString; DataSource: TSectionTextData); overload;
{$IFNDEF FPC} procedure PostAssembleStream(dbN: SystemString; DataSource: TJsonObject); overload; virtual; {$ENDIF}
    procedure PostAssembleStream(dbN: SystemString; DataSource: TPascalString); overload;
    //
    // Security insert support
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean); overload; virtual;
    procedure InsertAssembleStreamCopy(dbN: SystemString; dStorePos: Int64; stream: TCoreClassStream; dID: Cardinal);
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine); overload;
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList); overload;
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashStringList); overload;
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData); overload;
{$IFNDEF FPC} procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject); overload; {$ENDIF}
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString); overload;
    //
    // Security modify support
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; stream: TMemoryStream64; DoneTimeFree: Boolean); overload; virtual;
    procedure ModifyAssembleStreamCopy(dbN: SystemString; dStorePos: Int64; stream: TCoreClassStream);
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine); overload;
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList); overload;
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashStringList); overload;
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData); overload;
{$IFNDEF FPC} procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject); overload; {$ENDIF}
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString); overload;
    //
    procedure GetPostAssembleStreamStateM(OnResult: TStreamMethod); overload; virtual;
{$IFNDEF FPC} procedure GetPostAssembleStreamStateP(OnResult: TStreamProc); overload; virtual; {$ENDIF}
    //
    procedure EndAssembleStream; virtual;
    //
    procedure DeleteData(dbN: SystemString; dStorePos: Int64); virtual;
    //
    // fast post support
    procedure FastPostCompleteBuffer(dbN: SystemString; stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean); overload; virtual;
    procedure FastPostCompleteBufferCopy(dbN: SystemString; stream: TCoreClassStream; dID: Cardinal);
    procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: TDataFrameEngine); overload;
    procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: THashVariantList); overload;
    procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: THashStringList); overload;
    procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: TSectionTextData); overload;
{$IFNDEF FPC} procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: TJsonObject); overload; virtual; {$ENDIF}
    procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: TPascalString); overload;
    //
    // fast insert support
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean); overload; virtual;
    procedure FastInsertCompleteBufferCopy(dbN: SystemString; dStorePos: Int64; stream: TCoreClassStream; dID: Cardinal);
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine); overload;
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList); overload;
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashStringList); overload;
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData); overload;
{$IFNDEF FPC} procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject); overload; {$ENDIF}
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString); overload;
    //
    // fast modify support
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean); overload; virtual;
    procedure FastModifyCompleteBufferCopy(dbN: SystemString; dStorePos: Int64; stream: TCoreClassStream; dID: Cardinal);
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine); overload;
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList); overload;
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashStringList); overload;
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData); overload;
{$IFNDEF FPC} procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject); overload; {$ENDIF}
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString); overload;
    //
    //
    procedure GetDBListM(OnResult: TStreamMethod); overload; virtual;
    procedure GetQueryListM(OnResult: TStreamMethod); overload; virtual;
    procedure GetQueryStateM(pipeN: SystemString; OnResult: TStreamMethod); overload; virtual;
    procedure QueryStop(pipeN: SystemString); virtual;
    procedure QueryPause(pipeN: SystemString); virtual;
    procedure QueryPlay(pipeN: SystemString); virtual;
    //
{$IFNDEF FPC}
    procedure GetDBListP(OnResult: TStreamProc); overload; virtual;
    procedure GetQueryListP(OnResult: TStreamProc); overload; virtual;
    procedure GetQueryStateP(pipeN: SystemString; OnResult: TStreamProc); overload; virtual;
{$ENDIF}
  end;

implementation

const
  C_DataStoreSecurity = '__@DataStoreSecurity';
  C_CompletedFragmentBigStream = '__@CompletedFragmentBigStream';
  C_CompletedQuery = '__@CompletedQuery';
  C_CompletedDownloadAssemble = '__@CompletedDownloadAssemble';
  C_CompletedFastDownloadAssemble = '__@CompletedFastDownloadAssemble';
  C_CompletedStorePosTransform = '__@CompletedStorePosTransform';
  C_InitDB = '__@InitDB';
  C_CloseDB = '__@CloseDB';
  C_CopyDB = '__@CopyDB';
  C_CompressDB = '__@CompressDB';
  C_ReplaceDB = '__@ReplaceDB';
  C_ResetData = '__@ResetData';
  C_QueryDB = '__@QueryDB';
  C_DownloadDB = '__@DownloadDB';
  C_DownloadDBWithID = '__@DownloadDBWithID';
  C_RequestDownloadAssembleStream = '__@RequestDownloadAssembleStream';
  C_RequestFastDownloadAssembleStrea = '__@RequestFastDownloadAssembleStream';
  C_FastPostCompleteBuffer = '__@FastPostCompleteBuffer';
  C_FastInsertCompleteBuffer = '__@FastInsertCompleteBuffer';
  C_FastModifyCompleteBuffer = '__@FastModifyCompleteBuffer';
  C_CompletedPostAssembleStream = '__@CompletedPostAssembleStream';
  C_CompletedInsertAssembleStream = '__@CompletedInsertAssembleStream';
  C_CompletedModifyAssembleStream = '__@CompletedModifyAssembleStream';
  C_DeleteData = '__@DeleteData';
  C_GetDBList = '__@GetDBList';
  C_GetQueryList = '__@GetQueryList';
  C_GetQueryState = '__@GetQueryState';
  C_QueryStop = '__@QueryStop';
  C_QueryPause = '__@QueryPause';
  C_QueryPlay = '__@QueryPlay';

constructor TDataStoreService_PeerClientRecvTunnel.Create(AOwner: TPeerIO);
type
  TCipherDef = array [0 .. 4] of TCipherSecurity;
const
  c: TCipherDef = (csRC6, csSerpent, csMars, csRijndael, csTwoFish);
var
  kref: TInt64;
begin
  inherited Create(AOwner);
  FPostPerformaceCounter := 0;
  FLastPostPerformaceTime := GetTimeTick;
  FPostCounterOfPerSec := 0;

  FDataStoreCipherSecurity := c[umlRandomRange(0, 4)];

  // generate random key
  TMISC.GenerateRandomKey(kref, C_Int64_Size);
  TCipher.GenerateKey(FDataStoreCipherSecurity, @kref, C_Int64_Size, FDataStoreCipherKey);
end;

destructor TDataStoreService_PeerClientRecvTunnel.Destroy;
begin
  inherited Destroy;
end;

procedure TDataStoreService_PeerClientRecvTunnel.Progress;
var
  lastTime: TTimeTick;
begin
  lastTime := GetTimeTick;

  inherited Progress;

  if lastTime - FLastPostPerformaceTime > 1000 then
    begin
      try
        if FPostPerformaceCounter > 0 then
            FPostCounterOfPerSec := FPostPerformaceCounter / ((lastTime - FLastPostPerformaceTime) * 0.001)
        else
            FPostCounterOfPerSec := 0;
      except
          FPostCounterOfPerSec := 0;
      end;
      FLastPostPerformaceTime := lastTime;
      FPostPerformaceCounter := 0;
    end;
end;

function TDataStoreService_PeerClientRecvTunnel.SendTunnelDefine: TDataStoreService_PeerClientSendTunnel;
begin
  Result := SendTunnel as TDataStoreService_PeerClientSendTunnel;
end;

procedure TDataStoreService_PeerClientRecvTunnel.EncryptBuffer(sour: Pointer; Size: NativeInt; Encrypt: Boolean);
begin
  SequEncryptCBC(FDataStoreCipherSecurity, sour, Size, FDataStoreCipherKey, Encrypt, True);
end;

constructor TDataStoreService_PeerClientSendTunnel.Create(AOwner: TPeerIO);
begin
  inherited Create(AOwner);
end;

destructor TDataStoreService_PeerClientSendTunnel.Destroy;
begin
  inherited Destroy;
end;

function TDataStoreService_PeerClientSendTunnel.RecvTunnelDefine: TDataStoreService_PeerClientRecvTunnel;
begin
  Result := RecvTunnel as TDataStoreService_PeerClientRecvTunnel;
end;

procedure TDataStoreService.CreateQuery(pipe: TZDBPipeline);
var
  pl: TTDataStoreService_DBPipeline;
begin
  pl := TTDataStoreService_DBPipeline(pipe);
end;

procedure TDataStoreService.QueryFragmentData(pipe: TZDBPipeline; FragmentSource: TMemoryStream64);
var
  pl: TTDataStoreService_DBPipeline;
  DestStream: TMemoryStream64;
begin
  pl := TTDataStoreService_DBPipeline(pipe);
  if not pl.SyncToClient then
      Exit;

  if not SendTunnel.Exists(pl.SendTunnel) then
      Exit;

  DestStream := TMemoryStream64.Create;
  FragmentSource.Position := 0;

  CompressStream(FragmentSource, DestStream);

  TDataStoreService_PeerClientRecvTunnel(pl.RecvTunnel).EncryptBuffer(DestStream.Memory, DestStream.Size, True);

  ClearBatchStream(pl.SendTunnel.Owner);
  PostBatchStream(pl.SendTunnel.Owner, DestStream, True);
  Send_CompletedFragmentBigStream(pl);
  ClearBatchStream(pl.SendTunnel.Owner);
end;

procedure TDataStoreService.QueryDone(pipe: TZDBPipeline);
var
  pl: TTDataStoreService_DBPipeline;
begin
  pl := TTDataStoreService_DBPipeline(pipe);

  if not FSendTunnel.Exists(pl.SendTunnel) then
      Exit;

  Send_CompletedQuery(pl);
end;

procedure TDataStoreService.StorePosTransform(const Data: Pointer; const TransformBuff: PZDBStorePosTransformArray);
var
  p: POnStorePosTransformTrigger;
  de: TDataFrameEngine;
begin
  if Data = nil then
      Exit;
  p := POnStorePosTransformTrigger(Data);
  if (p^.BackcallPtr <> 0) and (FSendTunnel.Exists(p^.Client_SendTunnel_ID)) then
      Send_CompletedStorePosTransform(SendTunnel.PeerIO[p^.Client_SendTunnel_ID], p^.BackcallPtr, TransformBuff);
  Dispose(p);
end;

procedure TDataStoreService.CreateDB(ActiveDB: TZDBStoreEngine);
begin
end;

procedure TDataStoreService.CloseDB(ActiveDB: TZDBStoreEngine);
begin
end;

procedure TDataStoreService.InsertData(Sender: TZDBStoreEngine; InsertPos: Int64; buff: TCoreClassStream; ID: Cardinal; CompletePos: Int64);
begin
end;

procedure TDataStoreService.AddData(Sender: TZDBStoreEngine; buff: TCoreClassStream; ID: Cardinal; CompletePos: Int64);
begin
end;

procedure TDataStoreService.ModifyData(Sender: TZDBStoreEngine; const StorePos: Int64; buff: TCoreClassStream);
begin
end;

procedure TDataStoreService.DeleteData(Sender: TZDBStoreEngine; const StorePos: Int64);
begin
end;

procedure TDataStoreService.DownloadQueryFilterMethod(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
begin
  Allowed := True;
end;

procedure TDataStoreService.DownloadQueryWithIDFilterMethod(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
begin
  try
      Allowed := qState.ID = dPipe.UserVariant;
  except
      Allowed := False;
  end;
end;

procedure TDataStoreService.UserOut(UserDefineIO: TPeerClientUserDefineForRecvTunnel);
var
  i: Integer;
  pl: TTDataStoreService_DBPipeline;
begin
  for i := 0 to FZDBLocal.QueryPipelineList.Count - 1 do
    begin
      pl := TTDataStoreService_DBPipeline(FZDBLocal.QueryPipelineList[i]);
      if pl.RecvTunnel = UserDefineIO.Owner.UserDefine then
          pl.stop;
    end;
  inherited UserOut(UserDefineIO);
end;

procedure TDataStoreService.UserLinkSuccess(UserDefineIO: TPeerClientUserDefineForRecvTunnel);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  de: TDataFrameEngine;
  arr: TDataFrameArrayByte;
begin
  RT := UserDefineIO as TDataStoreService_PeerClientRecvTunnel;
  de := TDataFrameEngine.Create;
  de.WriteByte(Byte(RT.FDataStoreCipherSecurity));
  arr := de.WriteArrayByte;
  arr.AddPtrBuff(@RT.FDataStoreCipherKey[0], length(RT.FDataStoreCipherKey));
  RT.SendTunnel.Owner.SendDirectStreamCmd(C_DataStoreSecurity, de);
  DisposeObject(de);
  inherited UserLinkSuccess(UserDefineIO);
end;

procedure TDataStoreService.Command_InitDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  InMem: Boolean;
  dbN: SystemString;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  InMem := InData.Reader.ReadBool;
  dbN := InData.Reader.ReadString;
  if InMem then
      FZDBLocal.InitMemoryDB(dbN)
  else
      FZDBLocal.InitDB(dbN, False);
end;

procedure TDataStoreService.Command_CloseDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: SystemString;
  CloseAndDeleted: Boolean;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  dbN := InData.Reader.ReadString;
  CloseAndDeleted := InData.Reader.ReadBool;

  if CloseAndDeleted then
      FZDBLocal.CloseAndDeleteDB(dbN)
  else
      FZDBLocal.CloseDB(dbN);
end;

procedure TDataStoreService.Command_CopyDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN, copy2N: SystemString;
  BackcallPtr: UInt64;
  p: POnStorePosTransformTrigger;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  dbN := InData.Reader.ReadString;
  copy2N := InData.Reader.ReadString;
  BackcallPtr := InData.Reader.ReadPointer;

  new(p);
  p^.Client_SendTunnel_ID := RT.SendTunnelID;
  p^.BackcallPtr := BackcallPtr;
{$IFDEF FPC}
  FZDBLocal.CopyDB(dbN, copy2N, p, @StorePosTransform);
{$ELSE FPC}
  FZDBLocal.CopyDB(dbN, copy2N, p, StorePosTransform);
{$ENDIF FPC}
end;

procedure TDataStoreService.Command_CompressDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: SystemString;
  BackcallPtr: UInt64;
  p: POnStorePosTransformTrigger;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  dbN := InData.Reader.ReadString;
  BackcallPtr := InData.Reader.ReadPointer;

  new(p);
  p^.Client_SendTunnel_ID := RT.SendTunnelID;
  p^.BackcallPtr := BackcallPtr;
{$IFDEF FPC}
  FZDBLocal.CompressDB(dbN, p, @StorePosTransform);
{$ELSE FPC}
  FZDBLocal.CompressDB(dbN, p, StorePosTransform);
{$ENDIF FPC}
end;

procedure TDataStoreService.Command_ReplaceDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN, replaceN: SystemString;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  dbN := InData.Reader.ReadString;
  replaceN := InData.Reader.ReadString;
  FZDBLocal.ReplaceDB(dbN, replaceN);
end;

procedure TDataStoreService.Command_ResetData(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: SystemString;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  dbN := InData.Reader.ReadString;
  FZDBLocal.ResetData(dbN);
end;

procedure TDataStoreService.Command_QueryDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  RegedQueryName: SystemString;
  SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean;
  dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double;
  MaxQueryResult: Int64;

  AutoDestoryOutputDB: Boolean;
  DelayDestoryTime: Double;
  pl: TTDataStoreService_DBPipeline;
  qc: TTDataStoreService_QueryCall;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  RegedQueryName := InData.Reader.ReadString;
  SyncToClient := InData.Reader.ReadBool;
  WriteResultToOutputDB := InData.Reader.ReadBool;
  InMem := InData.Reader.ReadBool;
  ReverseQuery := InData.Reader.ReadBool;
  dbN := InData.Reader.ReadString;
  outDBN := InData.Reader.ReadString;
  fragmentReponseTime := InData.Reader.ReadDouble;
  MaxWait := InData.Reader.ReadDouble;
  MaxQueryResult := InData.Reader.ReadInt64;

  if not FZDBLocal.ExistsDB(dbN) then
      Exit;

  qc := TTDataStoreService_QueryCall(FQueryCallPool[RegedQueryName]);

  if InMem then
      AutoDestoryOutputDB := True
  else
      AutoDestoryOutputDB := False;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.QueryDB(WriteResultToOutputDB, InMem, ReverseQuery, dbN, outDBN,
    AutoDestoryOutputDB, FPerQueryPipelineDelayFreeTime, fragmentReponseTime, MaxWait, 0, MaxQueryResult));
  pl.SendTunnel := RT.SendTunnelDefine;
  pl.RecvTunnel := RT;
  pl.BackcallPtr := InData.Reader.ReadPointer;
  pl.SyncToClient := SyncToClient;
  pl.RegistedQuery := RegedQueryName;
  pl.WriteFragmentBuffer := pl.SyncToClient;

  if InData.Reader.NotEnd then
      InData.Reader.ReadVariantList(pl.values);

  if qc <> nil then
    begin
      pl.OnDataFilterMethod := qc.OnPipelineQuery;
      pl.OnDataDoneMethod := qc.OnPipelineQueryDone;
    end
  else
    begin
{$IFDEF FPC}
      pl.OnDataFilterMethod := @DownloadQueryFilterMethod;
{$ELSE}
      pl.OnDataFilterMethod := DownloadQueryFilterMethod;
{$ENDIF}
    end;
  ClearBatchStream(RT.SendTunnelDefine.Owner);
end;

procedure TDataStoreService.Command_DownloadDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  ReverseQuery: Boolean;
  dbN: SystemString;
  pl: TTDataStoreService_DBPipeline;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  ReverseQuery := InData.Reader.ReadBool;
  dbN := InData.Reader.ReadString;

  if not FZDBLocal.ExistsDB(dbN) then
      Exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.QueryDB(False, True, ReverseQuery, dbN, '', True, FPerQueryPipelineDelayFreeTime, 0.5, 0, 0, 0));
  pl.SendTunnel := RT.SendTunnelDefine;
  pl.RecvTunnel := RT;
  pl.BackcallPtr := InData.Reader.ReadPointer;
  pl.SyncToClient := True;
  pl.WriteFragmentBuffer := pl.SyncToClient;
  //
{$IFDEF FPC}
  pl.OnDataFilterMethod := @DownloadQueryFilterMethod;
{$ELSE}
  pl.OnDataFilterMethod := DownloadQueryFilterMethod;
{$ENDIF}
  ClearBatchStream(RT.SendTunnelDefine.Owner);
end;

procedure TDataStoreService.Command_DownloadDBWithID(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  ReverseQuery: Boolean;
  dbN: SystemString;
  downloadWithID: Cardinal;
  pl: TTDataStoreService_DBPipeline;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  ReverseQuery := InData.Reader.ReadBool;
  dbN := InData.Reader.ReadString;
  downloadWithID := InData.Reader.ReadCardinal;

  if not FZDBLocal.ExistsDB(dbN) then
      Exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.QueryDB(False, True, ReverseQuery, dbN, '', True, FPerQueryPipelineDelayFreeTime, 0.5, 0, 0, 0));
  pl.SendTunnel := RT.SendTunnelDefine;
  pl.RecvTunnel := RT;
  pl.BackcallPtr := InData.Reader.ReadPointer;
  pl.SyncToClient := True;
  pl.WriteFragmentBuffer := pl.SyncToClient;
  //
  // user download with ID
  pl.UserVariant := downloadWithID;
  //
{$IFDEF FPC}
  pl.OnDataFilterMethod := @DownloadQueryWithIDFilterMethod;
{$ELSE}
  pl.OnDataFilterMethod := DownloadQueryWithIDFilterMethod;
{$ENDIF}
  ClearBatchStream(RT.SendTunnelDefine.Owner);
end;

procedure TDataStoreService.Command_RequestDownloadAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: SystemString;
  StorePos: Int64;
  BackcallPtr: UInt64;
  M, CM: TMemoryStream64;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  dbN := InData.Reader.ReadString;
  StorePos := InData.Reader.ReadInt64;
  BackcallPtr := InData.Reader.ReadPointer;

  M := TMemoryStream64.Create;
  if not FZDBLocal.WriteDBItemToOneFragment(dbN, StorePos, M) then
    begin
      Sender.PrintParam('get Data Assemble Stream error: %s', dbN);
      DisposeObject(M);
      Exit;
    end;
  CM := TMemoryStream64.Create;
  M.Position := 0;
  CompressStream(M, CM);
  DisposeObject(M);

  RT.EncryptBuffer(CM.Memory, CM.Size, True);

  ClearBatchStream(RT.SendTunnelDefine.Owner);
  PostBatchStream(RT.SendTunnelDefine.Owner, CM, True);
  Send_CompletedDownloadAssemble(RT.SendTunnelDefine.Owner, dbN, StorePos, BackcallPtr);
  ClearBatchStream(RT.SendTunnelDefine.Owner);
end;

procedure TDataStoreService.Command_RequestFastDownloadAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: SystemString;
  StorePos: Int64;
  BackcallPtr: UInt64;
  M: TMemoryStream64;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  dbN := InData.Reader.ReadString;
  StorePos := InData.Reader.ReadInt64;
  BackcallPtr := InData.Reader.ReadPointer;

  M := TMemoryStream64.Create;
  if not FZDBLocal.WriteDBItemToOneFragment(dbN, StorePos, M) then
    begin
      Sender.PrintParam('get Data Assemble Stream error: %s', dbN);
      DisposeObject(M);
      Exit;
    end;

  ClearBatchStream(RT.SendTunnelDefine.Owner);
  PostBatchStream(RT.SendTunnelDefine.Owner, M, True);
  Send_CompletedFastDownloadAssemble(RT.SendTunnelDefine.Owner, dbN, StorePos, BackcallPtr);
  ClearBatchStream(RT.SendTunnelDefine.Owner);
end;

procedure TDataStoreService.Command_FastPostCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: TPascalString;
  itmID: Cardinal;
  StorePos: Int64;
  output: Pointer;
  outputSiz: nativeUInt;
  m64: TMemoryStream64;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;
  inc(RT.FPostPerformaceCounter);

  DecodeOneBuff(InData, DataSize, dbN, itmID, StorePos, output, outputSiz);
  m64 := TMemoryStream64.Create;
  m64.SetPointerWithProtectedMode(output, outputSiz);
  FZDBLocal.PostData(dbN, m64, itmID);
  DisposeObject(m64);
end;

procedure TDataStoreService.Command_FastInsertCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: TPascalString;
  itmID: Cardinal;
  StorePos: Int64;
  output: Pointer;
  outputSiz: nativeUInt;
  m64: TMemoryStream64;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;
  inc(RT.FPostPerformaceCounter);

  DecodeOneBuff(InData, DataSize, dbN, itmID, StorePos, output, outputSiz);
  m64 := TMemoryStream64.Create;
  m64.SetPointerWithProtectedMode(output, outputSiz);
  FZDBLocal.InsertData(dbN, StorePos, m64, itmID);
  DisposeObject(m64);
end;

procedure TDataStoreService.Command_FastModifyCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: TPascalString;
  itmID: Cardinal;
  StorePos: Int64;
  output: Pointer;
  outputSiz: nativeUInt;
  m64: TMemoryStream64;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;
  inc(RT.FPostPerformaceCounter);

  DecodeOneBuff(InData, DataSize, dbN, itmID, StorePos, output, outputSiz);
  m64 := TMemoryStream64.Create;
  m64.SetPointerWithProtectedMode(output, outputSiz);
  FZDBLocal.SetData(dbN, StorePos, m64);
  DisposeObject(m64);
end;

procedure TDataStoreService.Command_CompletedPostAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: SystemString;
  dID: Cardinal;
  p: PBigStreamBatchPostData;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  if RT.BigStreamBatchList.Count <= 0 then
      Exit;

  dbN := InData.Reader.ReadString;
  dID := InData.Reader.ReadCardinal;

  p := RT.BigStreamBatchList.Last;
  RT.EncryptBuffer(p^.Source.Memory, p^.Source.Size, False);
  p^.DBStorePos := FZDBLocal.PostData(dbN, p^.Source, dID);
  inc(RT.FPostPerformaceCounter);
end;

procedure TDataStoreService.Command_CompletedInsertAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: SystemString;
  dStorePos: Int64;
  dID: Cardinal;
  p: PBigStreamBatchPostData;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  if RT.BigStreamBatchList.Count <= 0 then
      Exit;

  dbN := InData.Reader.ReadString;
  dStorePos := InData.Reader.ReadInt64;
  dID := InData.Reader.ReadCardinal;

  p := RT.BigStreamBatchList.Last;
  RT.EncryptBuffer(p^.Source.Memory, p^.Source.Size, False);
  p^.DBStorePos := FZDBLocal.InsertData(dbN, dStorePos, p^.Source, dID);
  inc(RT.FPostPerformaceCounter);
end;

procedure TDataStoreService.Command_CompletedModifyAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: SystemString;
  dStorePos: Int64;
  p: PBigStreamBatchPostData;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  if RT.BigStreamBatchList.Count <= 0 then
      Exit;

  dbN := InData.Reader.ReadString;
  dStorePos := InData.Reader.ReadInt64;

  p := RT.BigStreamBatchList.Last;
  RT.EncryptBuffer(p^.Source.Memory, p^.Source.Size, False);

  if FZDBLocal.SetData(dbN, dStorePos, p^.Source) then
    begin
      p^.DBStorePos := dStorePos;
    end
  else
    begin
    end;
  inc(RT.FPostPerformaceCounter);
end;

procedure TDataStoreService.Command_DeleteData(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  dbN: SystemString;
  dStorePos: Int64;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  dbN := InData.Reader.ReadString;
  dStorePos := InData.Reader.ReadInt64;
  FZDBLocal.DeleteData(dbN, dStorePos);
  inc(RT.FPostPerformaceCounter);
end;

procedure TDataStoreService.Command_GetDBList(Sender: TPeerIO; InData, OutData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  lst: TCoreClassListForObj;
  i: Integer;
  db: TZDBStoreEngine;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  lst := TCoreClassListForObj.Create;
  FZDBLocal.GetDBList(lst);
  for i := 0 to lst.Count - 1 do
    begin
      db := TZDBStoreEngine(lst[i]);
      OutData.WriteString(db.Name);
    end;
  DisposeObject(lst);
end;

procedure TDataStoreService.Command_GetQueryList(Sender: TPeerIO; InData, OutData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  i: Integer;
  pl: TTDataStoreService_DBPipeline;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;
  for i := 0 to FZDBLocal.QueryPipelineList.Count - 1 do
    begin
      pl := TTDataStoreService_DBPipeline(FZDBLocal.QueryPipelineList[i]);
      if (pl.RecvTunnel <> nil) and (pl.RecvTunnel.Owner = Sender) and
        (pl.Activted) and (pl.SourceDB <> nil) and (pl.OutputDB <> nil) then
          OutData.WriteString(pl.PipelineName);
    end;
end;

procedure TDataStoreService.Command_GetQueryState(Sender: TPeerIO; InData, OutData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  pipeN: SystemString;
  pl: TTDataStoreService_DBPipeline;
  ps: TPipeState;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  pipeN := InData.Reader.ReadString;
  if not FZDBLocal.ExistsPipeline(pipeN) then
      Exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.PipelineN[pipeN]);
  if pl = nil then
      Exit;

  if not pl.Activted then
      Exit;
  if pl.SourceDB = nil then
      Exit;
  if pl.OutputDB = nil then
      Exit;

  ps.Init;
  ps.WriteOutputDB := (pl.WriteResultToOutputDB);
  ps.Activted := (pl.Activted);
  ps.SyncToClient := (pl.SyncToClient);
  ps.MemoryMode := (pl.OutputDB.IsMemoryMode);
  ps.Paused := (pl.Paused);
  ps.DBCounter := (pl.SourceDB.Count);
  ps.QueryCounter := (pl.QueryCounter);
  ps.QueryResultCounter := (pl.QueryResultCounter);
  ps.MaxQueryCompare := (pl.MaxQueryCompare);
  ps.MaxQueryResult := (pl.MaxQueryResult);
  ps.QueryPerformanceOfPerSec := (pl.QueryCounterOfPerSec);
  ps.ConsumTime := (pl.QueryConsumTime);
  ps.MaxWaitTime := (pl.MaxWaitTime);
  ps.SourceDB := (pl.SourceDBName);
  ps.OutputDB := (pl.OutputDBName);
  ps.PipelineName := (pl.PipelineName);
  ps.RegistedQuery := (pl.RegistedQuery);
  ps.Encode(OutData);
  ps.Init;
end;

procedure TDataStoreService.Command_QueryStop(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  pipeN: SystemString;
  pl: TTDataStoreService_DBPipeline;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  pipeN := InData.Reader.ReadString;
  if not FZDBLocal.ExistsPipeline(pipeN) then
      Exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.PipelineN[pipeN]);
  if pl <> nil then
      pl.stop;
end;

procedure TDataStoreService.Command_QueryPause(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  pipeN: SystemString;
  pl: TTDataStoreService_DBPipeline;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  pipeN := InData.Reader.ReadString;
  if not FZDBLocal.ExistsPipeline(pipeN) then
      Exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.PipelineN[pipeN]);
  if pl <> nil then
      pl.Pause;
end;

procedure TDataStoreService.Command_QueryPlay(Sender: TPeerIO; InData: TDataFrameEngine);
var
  RT: TDataStoreService_PeerClientRecvTunnel;
  pipeN: SystemString;
  pl: TTDataStoreService_DBPipeline;
begin
  RT := GetDataStoreUserDefine(Sender);
  if not RT.LinkOk then
      Exit;

  pipeN := InData.Reader.ReadString;
  if not FZDBLocal.ExistsPipeline(pipeN) then
      Exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.PipelineN[pipeN]);
  if pl <> nil then
      pl.Play;
end;

procedure TDataStoreService.Send_CompletedFragmentBigStream(pipe: TTDataStoreService_DBPipeline);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipe.SourceDBName);
  de.WriteString(pipe.OutputDBName);
  de.WriteString(pipe.PipelineName);
  de.WritePointer(pipe.BackcallPtr);
  pipe.SendTunnel.Owner.SendDirectStreamCmd(C_CompletedFragmentBigStream, de);
  DisposeObject(de);
end;

procedure TDataStoreService.Send_CompletedQuery(pipe: TTDataStoreService_DBPipeline);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipe.SourceDBName);
  de.WriteString(pipe.OutputDBName);
  de.WriteString(pipe.PipelineName);
  de.WritePointer(pipe.BackcallPtr);
  de.WriteInt64(pipe.QueryResultCounter);
  pipe.SendTunnel.Owner.SendDirectStreamCmd(C_CompletedQuery, de);
  DisposeObject(de);
  ClearBatchStream(pipe.SendTunnel.Owner);
end;

procedure TDataStoreService.Send_CompletedDownloadAssemble(ASendCli: TPeerIO; dbN: SystemString; dStorePos: Int64; BackcallPtr: UInt64);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteInt64(dStorePos);
  de.WritePointer(BackcallPtr);
  ASendCli.SendDirectStreamCmd(C_CompletedDownloadAssemble, de);
  DisposeObject(de);
  ClearBatchStream(ASendCli);
end;

procedure TDataStoreService.Send_CompletedFastDownloadAssemble(ASendCli: TPeerIO; dbN: SystemString; dStorePos: Int64; BackcallPtr: UInt64);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteInt64(dStorePos);
  de.WritePointer(BackcallPtr);
  ASendCli.SendDirectStreamCmd(C_CompletedFastDownloadAssemble, de);
  DisposeObject(de);
  ClearBatchStream(ASendCli);
end;

procedure TDataStoreService.Send_CompletedStorePosTransform(ASendCli: TPeerIO; const BackcallPtr: UInt64; const TransformBuff: PZDBStorePosTransformArray);
var
  de: TDataFrameEngine;
  i: Integer;
  arr: TDataFrameArrayInt64;
begin
  de := TDataFrameEngine.Create;
  de.WritePointer(BackcallPtr);

  arr := de.WriteArrayInt64;
  for i := 0 to length(TransformBuff^) - 1 do
      arr.Add(TransformBuff^[i].OriginPos);

  arr := de.WriteArrayInt64;
  for i := 0 to length(TransformBuff^) - 1 do
      arr.Add(TransformBuff^[i].NewPos);

  ASendCli.SendDirectStreamCmd(C_CompletedStorePosTransform, de);
  DisposeObject(de);
end;

constructor TDataStoreService.Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkServer);
begin
  inherited Create(ARecvTunnel, ASendTunnel);
  FRecvTunnel.PeerClientUserDefineClass := TDataStoreService_PeerClientRecvTunnel;
  FSendTunnel.PeerClientUserDefineClass := TDataStoreService_PeerClientSendTunnel;

  FZDBLocal := TZDBLocalManager.Create;
  FZDBLocal.PipelineClass := TTDataStoreService_DBPipeline;
  FZDBLocal.NotifyIntf := Self;

  FQueryCallPool := THashObjectList.Create(True);

  FPerQueryPipelineDelayFreeTime := 3.0;
end;

destructor TDataStoreService.Destroy;
begin
  DisposeObject([FZDBLocal, FQueryCallPool]);
  inherited Destroy;
end;

procedure TDataStoreService.RegisterCommand;
begin
  inherited RegisterCommand;

  FRecvTunnel.RegisterDirectStream(C_InitDB).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_InitDB;
  FRecvTunnel.RegisterDirectStream(C_CloseDB).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CloseDB;

  FRecvTunnel.RegisterDirectStream(C_CopyDB).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CopyDB;
  FRecvTunnel.RegisterDirectStream(C_CompressDB).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CompressDB;
  FRecvTunnel.RegisterDirectStream(C_ReplaceDB).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_ReplaceDB;
  FRecvTunnel.RegisterDirectStream(C_ResetData).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_ResetData;

  FRecvTunnel.RegisterDirectStream(C_QueryDB).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_QueryDB;
  FRecvTunnel.RegisterDirectStream(C_DownloadDB).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_DownloadDB;
  FRecvTunnel.RegisterDirectStream(C_DownloadDBWithID).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_DownloadDBWithID;
  FRecvTunnel.RegisterDirectStream(C_RequestDownloadAssembleStream).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_RequestDownloadAssembleStream;
  FRecvTunnel.RegisterDirectStream(C_RequestFastDownloadAssembleStrea).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_RequestFastDownloadAssembleStream;

  FRecvTunnel.RegisterCompleteBuffer(C_FastPostCompleteBuffer).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_FastPostCompleteBuffer;
  FRecvTunnel.RegisterCompleteBuffer(C_FastInsertCompleteBuffer).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_FastInsertCompleteBuffer;
  FRecvTunnel.RegisterCompleteBuffer(C_FastModifyCompleteBuffer).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_FastModifyCompleteBuffer;

  FRecvTunnel.RegisterDirectStream(C_CompletedPostAssembleStream).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CompletedPostAssembleStream;
  FRecvTunnel.RegisterDirectStream(C_CompletedInsertAssembleStream).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CompletedInsertAssembleStream;
  FRecvTunnel.RegisterDirectStream(C_CompletedModifyAssembleStream).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CompletedModifyAssembleStream;
  FRecvTunnel.RegisterDirectStream(C_DeleteData).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_DeleteData;

  FRecvTunnel.RegisterStream(C_GetDBList).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_GetDBList;
  FRecvTunnel.RegisterStream(C_GetQueryList).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_GetQueryList;
  FRecvTunnel.RegisterStream(C_GetQueryState).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_GetQueryState;
  FRecvTunnel.RegisterDirectStream(C_QueryStop).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_QueryStop;
  FRecvTunnel.RegisterDirectStream(C_QueryPause).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_QueryPause;
  FRecvTunnel.RegisterDirectStream(C_QueryPlay).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_QueryPlay;
end;

procedure TDataStoreService.UnRegisterCommand;
begin
  inherited UnRegisterCommand;
  FRecvTunnel.DeleteRegistedCMD(C_InitDB);
  FRecvTunnel.DeleteRegistedCMD(C_CloseDB);

  FRecvTunnel.DeleteRegistedCMD(C_CopyDB);
  FRecvTunnel.DeleteRegistedCMD(C_CompressDB);
  FRecvTunnel.DeleteRegistedCMD(C_ReplaceDB);
  FRecvTunnel.DeleteRegistedCMD(C_ResetData);

  FRecvTunnel.DeleteRegistedCMD(C_QueryDB);
  FRecvTunnel.DeleteRegistedCMD(C_DownloadDB);
  FRecvTunnel.DeleteRegistedCMD(C_RequestDownloadAssembleStream);

  FRecvTunnel.DeleteRegistedCMD(C_FastPostCompleteBuffer);
  FRecvTunnel.DeleteRegistedCMD(C_FastInsertCompleteBuffer);
  FRecvTunnel.DeleteRegistedCMD(C_FastModifyCompleteBuffer);

  FRecvTunnel.DeleteRegistedCMD(C_CompletedPostAssembleStream);
  FRecvTunnel.DeleteRegistedCMD(C_CompletedInsertAssembleStream);
  FRecvTunnel.DeleteRegistedCMD(C_CompletedModifyAssembleStream);
  FRecvTunnel.DeleteRegistedCMD(C_DeleteData);

  FRecvTunnel.DeleteRegistedCMD(C_GetDBList);
  FRecvTunnel.DeleteRegistedCMD(C_GetQueryList);
  FRecvTunnel.DeleteRegistedCMD(C_GetQueryState);
  FRecvTunnel.DeleteRegistedCMD(C_QueryStop);
  FRecvTunnel.DeleteRegistedCMD(C_QueryPause);
  FRecvTunnel.DeleteRegistedCMD(C_QueryPlay);
end;

procedure TDataStoreService.Progress;
begin
  inherited Progress;
  FZDBLocal.Progress;
end;

procedure TDataStoreService.CadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
begin
  inherited CadencerProgress(Sender, deltaTime, newTime);
end;

function TDataStoreService.GetDataStoreUserDefine(RecvCli: TPeerIO): TDataStoreService_PeerClientRecvTunnel;
begin
  Result := RecvCli.UserDefine as TDataStoreService_PeerClientRecvTunnel;
end;

function TDataStoreService.RegisterQueryCall(cName: SystemString): TTDataStoreService_QueryCall;
begin
  if FQueryCallPool.Exists(cName) then
      RaiseInfo('Query call already registed:%s', [cName]);

  Result := TTDataStoreService_QueryCall.Create;
  FQueryCallPool[cName] := Result;
end;

procedure TDataStoreService.UnRegisterQueryCall(cName: SystemString);
begin
  if not FQueryCallPool.Exists(cName) then
      RaiseInfo('Query call not registed:%s', [cName]);

  FQueryCallPool.Delete(cName);
end;

function TDataStoreService.GetRegistedQueryCall(cName: SystemString): TTDataStoreService_QueryCall;
begin
  Result := TTDataStoreService_QueryCall(FQueryCallPool[cName]);
end;

function TDataStoreService.PostCounterOfPerSec: Double;
var
  IO_Array: TIO_Array;
  pcid: Cardinal;
  RT: TDataStoreService_PeerClientRecvTunnel;
begin
  Result := 0;
  FRecvTunnel.GetIO_Array(IO_Array);
  for pcid in IO_Array do
    begin
      RT := GetDataStoreUserDefine(FRecvTunnel.PeerIO[pcid]);
      Result := Result + RT.FPostCounterOfPerSec;
    end;
end;

procedure TDataStoreClient.EncryptBuffer(sour: Pointer; Size: NativeInt; Encrypt: Boolean);
begin
  SequEncryptCBC(FDataStoreCipherSecurity, sour, Size, FDataStoreCipherKey, Encrypt, True);
end;

procedure TDataStoreClient.Command_DataStoreSecurity(Sender: TPeerIO; InData: TDataFrameEngine);
var
  arr: TDataFrameArrayByte;
begin
  FDataStoreCipherSecurity := TCipherSecurity(InData.Reader.ReadByte);
  arr := InData.Reader.ReadArrayByte;
  SetLength(FDataStoreCipherKey, arr.Count);
  arr.GetBuff(@FDataStoreCipherKey[0]);
end;

procedure TDataStoreClient.Command_CompletedFragmentBigStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  dbN, outN, pipeN: SystemString;
  BackcallPtr: PDataStoreClientQueryNotify;
  M: TMemoryStream64;
begin
  dbN := InData.Reader.ReadString;
  outN := InData.Reader.ReadString;
  pipeN := InData.Reader.ReadString;
  BackcallPtr := PDataStoreClientQueryNotify(InData.Reader.ReadPointer);

  M := TMemoryStream64.Create;

  if Sender.UserDefine.BigStreamBatchList.Count > 0 then
    begin
      Sender.UserDefine.BigStreamBatchList.Last^.Source.Position := 0;
      EncryptBuffer(Sender.UserDefine.BigStreamBatchList.Last^.Source.Memory, Sender.UserDefine.BigStreamBatchList.Last^.Source.Size, False);
      Sender.UserDefine.BigStreamBatchList.Last^.Source.Position := 0;
      DecompressStream(Sender.UserDefine.BigStreamBatchList.Last^.Source, M);
      Sender.UserDefine.BigStreamBatchList.DeleteLast;
    end;

  if (BackcallPtr <> nil) and (M.Size > 0) then
    begin
      try
        M.Position := 0;
        if Assigned(BackcallPtr^.OnUserQueryCall) then
          begin
            FillFragmentSource(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, pipeN, M, BackcallPtr^.OnUserQueryCall);
            M.Position := 0;
          end;
        if Assigned(BackcallPtr^.OnUserQueryMethod) then
          begin
            FillFragmentSource(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, pipeN, M, BackcallPtr^.OnUserQueryMethod);
            M.Position := 0;
          end;
{$IFNDEF FPC}
        if Assigned(BackcallPtr^.OnUserQueryProc) then
          begin
            FillFragmentSource(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, pipeN, M, BackcallPtr^.OnUserQueryProc);
            M.Position := 0;
          end;
{$ENDIF}
        //
        if Assigned(BackcallPtr^.OnQueryCall) then
          begin
            FillFragmentSource(dbN, pipeN, M, BackcallPtr^.OnQueryCall);
            M.Position := 0;
          end;
        if Assigned(BackcallPtr^.OnQueryMethod) then
          begin
            FillFragmentSource(dbN, pipeN, M, BackcallPtr^.OnQueryMethod);
            M.Position := 0;
          end;
{$IFNDEF FPC}
        if Assigned(BackcallPtr^.OnQueryProc) then
          begin
            FillFragmentSource(dbN, pipeN, M, BackcallPtr^.OnQueryProc);
            M.Position := 0;
          end;
{$ENDIF}
      except
      end;
    end;

  DisposeObject(M);
end;

procedure TDataStoreClient.Command_CompletedQuery(Sender: TPeerIO; InData: TDataFrameEngine);
var
  dbN, outN, pipeN: SystemString;
  BackcallPtr: PDataStoreClientQueryNotify;
  TotalResultCount: Int64;
begin
  dbN := InData.Reader.ReadString;
  outN := InData.Reader.ReadString;
  pipeN := InData.Reader.ReadString;
  BackcallPtr := PDataStoreClientQueryNotify(InData.Reader.ReadPointer);
  TotalResultCount := InData.Reader.ReadInt64;

  if BackcallPtr <> nil then
    begin
      try
        if Assigned(BackcallPtr^.OnUserDoneCall) then
            BackcallPtr^.OnUserDoneCall(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, outN, pipeN, TotalResultCount);
        if Assigned(BackcallPtr^.OnUserDoneMethod) then
            BackcallPtr^.OnUserDoneMethod(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, outN, pipeN, TotalResultCount);
{$IFNDEF FPC}
        if Assigned(BackcallPtr^.OnUserDoneProc) then
            BackcallPtr^.OnUserDoneProc(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, outN, pipeN, TotalResultCount);
{$ENDIF}
        //
        if Assigned(BackcallPtr^.OnDoneCall) then
            BackcallPtr^.OnDoneCall(dbN, outN, pipeN, TotalResultCount);
        if Assigned(BackcallPtr^.OnDoneMethod) then
            BackcallPtr^.OnDoneMethod(dbN, outN, pipeN, TotalResultCount);
{$IFNDEF FPC}
        if Assigned(BackcallPtr^.OnDoneProc) then
            BackcallPtr^.OnDoneProc(dbN, outN, pipeN, TotalResultCount);
{$ENDIF}
      except
      end;
      Dispose(BackcallPtr);
    end;
  Sender.UserDefine.BigStreamBatchList.Clear;
end;

procedure TDataStoreClient.Command_CompletedDownloadAssemble(Sender: TPeerIO; InData: TDataFrameEngine);
var
  dbN: SystemString;
  dStorePos: Int64;
  BackcallPtr: PDataStoreClientDownloadNotify;
  M, CM: TMemoryStream64;
begin
  dbN := InData.Reader.ReadString;
  dStorePos := InData.Reader.ReadInt64;
  BackcallPtr := PDataStoreClientDownloadNotify(InData.Reader.ReadPointer);

  if Sender.UserDefine.BigStreamBatchList.Count > 0 then
      M := Sender.UserDefine.BigStreamBatchList.Last^.Source
  else
      M := nil;

  if BackcallPtr <> nil then
    begin
      if M <> nil then
        begin
          CM := TMemoryStream64.Create;
          EncryptBuffer(M.Memory, M.Size, False);
          DecompressStream(M, CM);
          Sender.UserDefine.BigStreamBatchList.DeleteLast;

          try
            CM.Position := 0;
            if Assigned(BackcallPtr^.OnUserDoneCall) then
              begin
                BackcallPtr^.OnUserDoneCall(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, CM);
                CM.Position := 0;
              end;
            if Assigned(BackcallPtr^.OnUserDoneMethod) then
              begin
                BackcallPtr^.OnUserDoneMethod(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, CM);
                CM.Position := 0;
              end;
{$IFNDEF FPC}
            if Assigned(BackcallPtr^.OnUserDoneProc) then
              begin
                BackcallPtr^.OnUserDoneProc(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, CM);
                CM.Position := 0;
              end;
{$ENDIF}
            //
            if Assigned(BackcallPtr^.OnDoneCall) then
              begin
                BackcallPtr^.OnDoneCall(dbN, dStorePos, CM);
                CM.Position := 0;
              end;
            if Assigned(BackcallPtr^.OnDoneMethod) then
              begin
                BackcallPtr^.OnDoneMethod(dbN, dStorePos, CM);
                CM.Position := 0;
              end;
{$IFNDEF FPC}
            if Assigned(BackcallPtr^.OnDoneProc) then
              begin
                BackcallPtr^.OnDoneProc(dbN, dStorePos, CM);
                CM.Position := 0;
              end;
{$ENDIF}
            DisposeObject(CM);
          except
          end;
        end;
      Dispose(BackcallPtr);
    end;
end;

procedure TDataStoreClient.Command_CompletedFastDownloadAssemble(Sender: TPeerIO; InData: TDataFrameEngine);
var
  dbN: SystemString;
  dStorePos: Int64;
  BackcallPtr: PDataStoreClientDownloadNotify;
  M: TMemoryStream64;
begin
  dbN := InData.Reader.ReadString;
  dStorePos := InData.Reader.ReadInt64;
  BackcallPtr := PDataStoreClientDownloadNotify(InData.Reader.ReadPointer);

  if Sender.UserDefine.BigStreamBatchList.Count > 0 then
      M := Sender.UserDefine.BigStreamBatchList.Last^.Source
  else
      M := nil;

  if BackcallPtr <> nil then
    begin
      if M <> nil then
        begin
          try
            M.Position := 0;
            if Assigned(BackcallPtr^.OnUserDoneCall) then
              begin
                BackcallPtr^.OnUserDoneCall(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, M);
                M.Position := 0;
              end;
            if Assigned(BackcallPtr^.OnUserDoneMethod) then
              begin
                BackcallPtr^.OnUserDoneMethod(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, M);
                M.Position := 0;
              end;
{$IFNDEF FPC}
            if Assigned(BackcallPtr^.OnUserDoneProc) then
              begin
                BackcallPtr^.OnUserDoneProc(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, M);
                M.Position := 0;
              end;
{$ENDIF}
            //
            if Assigned(BackcallPtr^.OnDoneCall) then
              begin
                BackcallPtr^.OnDoneCall(dbN, dStorePos, M);
                M.Position := 0;
              end;
            if Assigned(BackcallPtr^.OnDoneMethod) then
              begin
                BackcallPtr^.OnDoneMethod(dbN, dStorePos, M);
                M.Position := 0;
              end;
{$IFNDEF FPC}
            if Assigned(BackcallPtr^.OnDoneProc) then
              begin
                BackcallPtr^.OnDoneProc(dbN, dStorePos, M);
                M.Position := 0;
              end;
{$ENDIF}
          except
          end;
          Sender.UserDefine.BigStreamBatchList.DeleteLast;
        end;
      Dispose(BackcallPtr);
    end;
end;

procedure TDataStoreClient.Command_CompletedStorePosTransform(Sender: TPeerIO; InData: TDataFrameEngine);
var
  BackcallPtr: PStorePosTransformNotify;
  arr: TDataFrameArrayInt64;
  i: Integer;
  TransformBuff: TZDBStorePosTransformArray;
begin
  BackcallPtr := PStorePosTransformNotify(InData.Reader.ReadPointer);

  arr := InData.Reader.ReadArrayInt64;
  SetLength(TransformBuff, arr.Count);
  for i := 0 to arr.Count - 1 do
      TransformBuff[i].OriginPos := arr[i];

  arr := InData.Reader.ReadArrayInt64;
  for i := 0 to arr.Count - 1 do
      TransformBuff[i].NewPos := arr[i];

  if BackcallPtr <> nil then
    begin
      if Assigned(BackcallPtr^.OnDoneCall) then
          BackcallPtr^.OnDoneCall(@TransformBuff);
      if Assigned(BackcallPtr^.OnDoneMethod) then
          BackcallPtr^.OnDoneMethod(@TransformBuff);
{$IFNDEF FPC}
      if Assigned(BackcallPtr^.OnDoneProc) then
          BackcallPtr^.OnDoneProc(@TransformBuff);
{$ENDIF FPC}
    end;

  SetLength(TransformBuff, 0);
  Dispose(BackcallPtr);
end;

constructor TDataStoreClient.Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkClient);
begin
  inherited Create(ARecvTunnel, ASendTunnel);
  FDataStoreCipherSecurity := TCipherSecurity.csNone;
  SetLength(FDataStoreCipherKey, 0);
end;

destructor TDataStoreClient.Destroy;
begin
  inherited Destroy;
end;

procedure TDataStoreClient.RegisterCommand;
begin
  inherited RegisterCommand;
  FRecvTunnel.RegisterDirectStream(C_DataStoreSecurity).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_DataStoreSecurity;
  FRecvTunnel.RegisterDirectStream(C_CompletedFragmentBigStream).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CompletedFragmentBigStream;
  FRecvTunnel.RegisterDirectStream(C_CompletedQuery).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CompletedQuery;
  FRecvTunnel.RegisterDirectStream(C_CompletedDownloadAssemble).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CompletedDownloadAssemble;
  FRecvTunnel.RegisterDirectStream(C_CompletedFastDownloadAssemble).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CompletedFastDownloadAssemble;
  FRecvTunnel.RegisterDirectStream(C_CompletedStorePosTransform).OnExecute := {$IFDEF FPC}@{$ENDIF FPC}Command_CompletedStorePosTransform;
end;

procedure TDataStoreClient.UnRegisterCommand;
begin
  inherited UnRegisterCommand;
  FRecvTunnel.DeleteRegistedCMD(C_CompletedFragmentBigStream);
  FRecvTunnel.DeleteRegistedCMD(C_CompletedQuery);
  FRecvTunnel.DeleteRegistedCMD(C_CompletedDownloadAssemble);
  FRecvTunnel.DeleteRegistedCMD(C_CompletedFastDownloadAssemble);
  FRecvTunnel.DeleteRegistedCMD(C_CompletedStorePosTransform);
end;

procedure TDataStoreClient.Progress;
begin
  inherited Progress;
end;

function TDataStoreClient.DataCipherKeyFinished: Boolean;
begin
  Result := (length(FDataStoreCipherKey) > 0) or (Self.FDataStoreCipherSecurity <> csNone);
end;

procedure TDataStoreClient.InitDB(InMem: Boolean; dbN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteBool(InMem);
  de.WriteString(dbN);

  SendTunnel.SendDirectStreamCmd(C_InitDB, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.CloseDB(dbN: SystemString; CloseAndDeleted: Boolean);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteBool(CloseAndDeleted);
  SendTunnel.SendDirectStreamCmd(C_CloseDB, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.CopyDB(dbN, copyToN: SystemString);
begin
  CopyDB(dbN, copyToN, nil);
end;

procedure TDataStoreClient.CopyDB(dbN, copyToN: SystemString; const BackcallPtr: PStorePosTransformNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteString(copyToN);
  de.WritePointer(BackcallPtr);
  SendTunnel.SendDirectStreamCmd(C_CopyDB, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.CopyDB_C(dbN, copyToN: SystemString; const OnDoneCall: TStorePosTransformNotifyCall);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneCall := OnDoneCall;
  CopyDB(dbN, copyToN, p);
end;

procedure TDataStoreClient.CopyDB_M(dbN, copyToN: SystemString; const OnDoneMethod: TStorePosTransformNotifyMethod);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneMethod := OnDoneMethod;
  CopyDB(dbN, copyToN, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.CopyDB_P(dbN, copyToN: SystemString; const OnDoneProc: TStorePosTransformNotifyProc);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneProc := OnDoneProc;
  CopyDB(dbN, copyToN, p);
end;
{$ENDIF FPC}


procedure TDataStoreClient.CompressDB(dbN: SystemString);
begin
  CompressDB(dbN, nil);
end;

procedure TDataStoreClient.CompressDB(dbN: SystemString; const BackcallPtr: PStorePosTransformNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WritePointer(BackcallPtr);
  SendTunnel.SendDirectStreamCmd(C_CompressDB, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.CompressDB_C(dbN: SystemString; const OnDoneCall: TStorePosTransformNotifyCall);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneCall := OnDoneCall;
  CompressDB(dbN, p);
end;

procedure TDataStoreClient.CompressDB_M(dbN: SystemString; const OnDoneMethod: TStorePosTransformNotifyMethod);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneMethod := OnDoneMethod;
  CompressDB(dbN, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.CompressDB_P(dbN: SystemString; const OnDoneProc: TStorePosTransformNotifyProc);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneProc := OnDoneProc;
  CompressDB(dbN, p);
end;
{$ENDIF FPC}


procedure TDataStoreClient.ReplaceDB(dbN, replaceN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteString(replaceN);
  SendTunnel.SendDirectStreamCmd(C_ReplaceDB, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.ResetData(dbN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  SendTunnel.SendDirectStreamCmd(C_ResetData, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.QuietQueryDB(RegistedQueryName: SystemString; ReverseQuery: Boolean; dbN, outDBN: SystemString; MaxWait: Double; MaxQueryResult: Int64);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteString(RegistedQueryName);
  de.WriteBool(False); // sync to client
  de.WriteBool(True);  // write output db
  de.WriteBool(False); // in memory
  de.WriteBool(ReverseQuery);
  de.WriteString(dbN);
  de.WriteString(outDBN);
  de.WriteDouble(0.1); // fragmentReponseTime
  de.WriteDouble(MaxWait);
  de.WriteInt64(MaxQueryResult);
  de.WritePointer(0); // backcall address

  SendTunnel.SendDirectStreamCmd(C_QueryDB, de);

  DisposeObject(de);
end;

procedure TDataStoreClient.QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64; BackcallPtr: PDataStoreClientQueryNotify; RemoteParams: THashVariantList);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteString(RegistedQueryName);
  de.WriteBool(SyncToClient); // sync to client
  de.WriteBool(WriteResultToOutputDB);
  de.WriteBool(InMem);
  de.WriteBool(ReverseQuery);
  de.WriteString(dbN);
  de.WriteString(outDBN);
  de.WriteDouble(fragmentReponseTime);
  de.WriteDouble(MaxWait);
  de.WriteInt64(MaxQueryResult);
  de.WritePointer(BackcallPtr);
  if RemoteParams <> nil then
      de.WriteVariantList(RemoteParams);

  SendTunnel.SendDirectStreamCmd(C_QueryDB, de);

  DisposeObject(de);
end;

procedure TDataStoreClient.QueryDBC(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryCall := OnQueryCall;
  p^.OnDoneCall := OnDoneCall;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

procedure TDataStoreClient.QueryDBC(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList;                                           // service ref remote parameter
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnQueryCall: TUserFillQueryDataCall; OnDoneCall: TUserQueryDoneNotifyCall);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserQueryCall := OnQueryCall;
  p^.OnUserDoneCall := OnDoneCall;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

procedure TDataStoreClient.QueryDBM(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryMethod := OnQueryMethod;
  p^.OnDoneMethod := OnDoneMethod;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

procedure TDataStoreClient.QueryDBM(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList;                                           // service ref remote parameter
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnQueryMethod: TUserFillQueryDataMethod; OnDoneMethod: TUserQueryDoneNotifyMethod);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserQueryMethod := OnQueryMethod;
  p^.OnUserDoneMethod := OnDoneMethod;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.QueryDBP(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryProc := OnQueryProc;
  p^.OnDoneProc := OnDoneProc;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

procedure TDataStoreClient.QueryDBP(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList;                                           // service ref remote parameter
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnQueryProc: TUserFillQueryDataProc; OnDoneProc: TUserQueryDoneNotifyProc);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserQueryProc := OnQueryProc;
  p^.OnUserDoneProc := OnDoneProc;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, InMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

{$ENDIF}


procedure TDataStoreClient.QueryDBC(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryCall := OnQueryCall;
  p^.OnDoneCall := OnDoneCall;
  QueryDB(RegistedQueryName, True, False, True, False, dbN, 'Memory', 0.5, 0, 0, p, RemoteParams);
end;

procedure TDataStoreClient.QueryDBM(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryMethod := OnQueryMethod;
  p^.OnDoneMethod := OnDoneMethod;
  QueryDB(RegistedQueryName, True, False, True, False, dbN, 'Memory', 0.5, 0, 0, p, RemoteParams);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.QueryDBP(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryProc := OnQueryProc;
  p^.OnDoneProc := OnDoneProc;
  QueryDB(RegistedQueryName, True, False, True, False, dbN, 'Memory', 0.5, 0, 0, p, RemoteParams);
end;
{$ENDIF}


procedure TDataStoreClient.DownloadDB(ReverseQuery: Boolean; dbN: SystemString; BackcallPtr: PDataStoreClientQueryNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteBool(ReverseQuery);
  de.WriteString(dbN);
  de.WritePointer(BackcallPtr);

  SendTunnel.SendDirectStreamCmd(C_DownloadDB, de);

  DisposeObject(de);
end;

procedure TDataStoreClient.DownloadDBC(ReverseQuery: Boolean; dbN: SystemString; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryCall := OnQueryCall;
  p^.OnDoneCall := OnDoneCall;
  DownloadDB(ReverseQuery, dbN, p);
end;

procedure TDataStoreClient.DownloadDBM(ReverseQuery: Boolean; dbN: SystemString; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryMethod := OnQueryMethod;
  p^.OnDoneMethod := OnDoneMethod;
  DownloadDB(ReverseQuery, dbN, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.DownloadDBP(ReverseQuery: Boolean; dbN: SystemString; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryProc := OnQueryProc;
  p^.OnDoneProc := OnDoneProc;
  DownloadDB(ReverseQuery, dbN, p);
end;
{$ENDIF}


procedure TDataStoreClient.DownloadDBWithID(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; BackcallPtr: PDataStoreClientQueryNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteBool(ReverseQuery);
  de.WriteString(dbN);
  de.WriteCardinal(db_ID);
  de.WritePointer(BackcallPtr);

  SendTunnel.SendDirectStreamCmd(C_DownloadDBWithID, de);

  DisposeObject(de);
end;

procedure TDataStoreClient.DownloadDBWithIDC(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryCall := OnQueryCall;
  p^.OnDoneCall := OnDoneCall;
  DownloadDBWithID(ReverseQuery, dbN, db_ID, p);
end;

procedure TDataStoreClient.DownloadDBWithIDM(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryMethod := OnQueryMethod;
  p^.OnDoneMethod := OnDoneMethod;
  DownloadDBWithID(ReverseQuery, dbN, db_ID, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.DownloadDBWithIDP(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryProc := OnQueryProc;
  p^.OnDoneProc := OnDoneProc;
  DownloadDBWithID(ReverseQuery, dbN, db_ID, p);
end;
{$ENDIF}


procedure TDataStoreClient.BeginAssembleStream;
begin
  ClearBatchStream;
end;

procedure TDataStoreClient.RequestDownloadAssembleStream(dbN: SystemString; StorePos: Int64; BackcallPtr: PDataStoreClientDownloadNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteString(dbN);
  de.WriteInt64(StorePos);
  de.WritePointer(BackcallPtr);

  SendTunnel.SendDirectStreamCmd(C_RequestDownloadAssembleStream, de);

  DisposeObject(de);
end;

procedure TDataStoreClient.DownloadAssembleStreamC(dbN: SystemString; StorePos: Int64; OnDoneCall: TDownloadDoneNotifyCall);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneCall := OnDoneCall;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;

procedure TDataStoreClient.DownloadAssembleStreamM(dbN: SystemString; StorePos: Int64; OnDoneMethod: TDownloadDoneNotifyMethod);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneMethod := OnDoneMethod;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.DownloadAssembleStreamP(dbN: SystemString; StorePos: Int64; OnDoneProc: TDownloadDoneNotifyProc);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneProc := OnDoneProc;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;
{$ENDIF}


procedure TDataStoreClient.DownloadAssembleStreamC(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneCall: TUserDownloadDoneNotifyCall);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneCall := OnDoneCall;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;

procedure TDataStoreClient.DownloadAssembleStreamM(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneMethod: TUserDownloadDoneNotifyMethod);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneMethod := OnDoneMethod;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.DownloadAssembleStreamP(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneProc: TUserDownloadDoneNotifyProc);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneProc := OnDoneProc;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;
{$ENDIF}


procedure TDataStoreClient.RequestFastDownloadAssembleStream(dbN: SystemString; StorePos: Int64; BackcallPtr: PDataStoreClientDownloadNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteString(dbN);
  de.WriteInt64(StorePos);
  de.WritePointer(BackcallPtr);

  SendTunnel.SendDirectStreamCmd(C_RequestFastDownloadAssembleStrea, de);

  DisposeObject(de);
end;

procedure TDataStoreClient.FastDownloadAssembleStreamC(dbN: SystemString; StorePos: Int64; OnDoneCall: TDownloadDoneNotifyCall);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneCall := OnDoneCall;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;

procedure TDataStoreClient.FastDownloadAssembleStreamM(dbN: SystemString; StorePos: Int64; OnDoneMethod: TDownloadDoneNotifyMethod);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneMethod := OnDoneMethod;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.FastDownloadAssembleStreamP(dbN: SystemString; StorePos: Int64; OnDoneProc: TDownloadDoneNotifyProc);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneProc := OnDoneProc;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;
{$ENDIF}


procedure TDataStoreClient.FastDownloadAssembleStreamC(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneCall: TUserDownloadDoneNotifyCall);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneCall := OnDoneCall;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;

procedure TDataStoreClient.FastDownloadAssembleStreamM(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneMethod: TUserDownloadDoneNotifyMethod);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneMethod := OnDoneMethod;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.FastDownloadAssembleStreamP(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneProc: TUserDownloadDoneNotifyProc);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneProc := OnDoneProc;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;
{$ENDIF}


procedure TDataStoreClient.PostAssembleStream(dbN: SystemString; stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean);
var
  de: TDataFrameEngine;
begin
  EncryptBuffer(stream.Memory, stream.Size, True);
  PostBatchStream(stream, DoneTimeFree);

  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteCardinal(dID);
  SendTunnel.SendDirectStreamCmd(C_CompletedPostAssembleStream, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.PostAssembleStreamCopy(dbN: SystemString; stream: TCoreClassStream; dID: Cardinal);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  stream.Position := 0;
  M.CopyFrom(stream, stream.Size);
  M.Position := 0;
  PostAssembleStream(dbN, M, dID, True);
end;

procedure TDataStoreClient.PostAssembleStream(dbN: SystemString; DataSource: TDataFrameEngine);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.EncodeTo(M, True);
  PostAssembleStream(dbN, M, c_DF, True);
end;

procedure TDataStoreClient.PostAssembleStream(dbN: SystemString; DataSource: THashVariantList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  PostAssembleStream(dbN, M, c_VL, True);
end;

procedure TDataStoreClient.PostAssembleStream(dbN: SystemString; DataSource: THashStringList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  PostAssembleStream(dbN, M, c_VT, True);
end;

procedure TDataStoreClient.PostAssembleStream(dbN: SystemString; DataSource: TSectionTextData);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  PostAssembleStream(dbN, M, c_TE, True);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.PostAssembleStream(dbN: SystemString; DataSource: TJsonObject);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  PostAssembleStream(dbN, M, c_Json, True);
end;
{$ENDIF}


procedure TDataStoreClient.PostAssembleStream(dbN: SystemString; DataSource: TPascalString);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, M);
  PostAssembleStream(dbN, M, c_PascalString, True);
end;

procedure TDataStoreClient.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean);
var
  de: TDataFrameEngine;
begin
  EncryptBuffer(stream.Memory, stream.Size, True);
  PostBatchStream(stream, DoneTimeFree);

  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteInt64(dStorePos);
  de.WriteCardinal(dID);
  SendTunnel.SendDirectStreamCmd(C_CompletedInsertAssembleStream, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.InsertAssembleStreamCopy(dbN: SystemString; dStorePos: Int64; stream: TCoreClassStream; dID: Cardinal);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  stream.Position := 0;
  M.CopyFrom(stream, stream.Size);
  M.Position := 0;
  InsertAssembleStream(dbN, dStorePos, M, dID, True);
end;

procedure TDataStoreClient.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.EncodeTo(M, True);
  InsertAssembleStream(dbN, dStorePos, M, c_DF, True);
end;

procedure TDataStoreClient.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  InsertAssembleStream(dbN, dStorePos, M, c_VL, True);
end;

procedure TDataStoreClient.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashStringList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  InsertAssembleStream(dbN, dStorePos, M, c_VT, True);
end;

procedure TDataStoreClient.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  InsertAssembleStream(dbN, dStorePos, M, c_TE, True);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M, False, TEncoding.UTF8, True);
  InsertAssembleStream(dbN, dStorePos, M, c_Json, True);
end;
{$ENDIF}


procedure TDataStoreClient.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, M);
  InsertAssembleStream(dbN, dStorePos, M, c_PascalString, True);
end;

procedure TDataStoreClient.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; stream: TMemoryStream64; DoneTimeFree: Boolean);
var
  de: TDataFrameEngine;
begin
  EncryptBuffer(stream.Memory, stream.Size, True);

  PostBatchStream(stream, DoneTimeFree);

  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteInt64(dStorePos);
  SendTunnel.SendDirectStreamCmd(C_CompletedModifyAssembleStream, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.ModifyAssembleStreamCopy(dbN: SystemString; dStorePos: Int64; stream: TCoreClassStream);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  stream.Position := 0;
  M.CopyFrom(stream, stream.Size);
  M.Position := 0;
  ModifyAssembleStream(dbN, dStorePos, M, True);
end;

procedure TDataStoreClient.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.EncodeTo(M, True);
  ModifyAssembleStream(dbN, dStorePos, M, True);
end;

procedure TDataStoreClient.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  ModifyAssembleStream(dbN, dStorePos, M, True);
end;

procedure TDataStoreClient.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashStringList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  ModifyAssembleStream(dbN, dStorePos, M, True);
end;

procedure TDataStoreClient.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  ModifyAssembleStream(dbN, dStorePos, M, True);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M, False, TEncoding.UTF8, True);
  ModifyAssembleStream(dbN, dStorePos, M, True);
end;
{$ENDIF}


procedure TDataStoreClient.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, M);
  ModifyAssembleStream(dbN, dStorePos, M, True);
end;

procedure TDataStoreClient.GetPostAssembleStreamStateM(OnResult: TStreamMethod);
begin
  GetBatchStreamStateM(OnResult);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.GetPostAssembleStreamStateP(OnResult: TStreamProc);
begin
  GetBatchStreamStateP(OnResult);
end;
{$ENDIF}


procedure TDataStoreClient.EndAssembleStream;
begin
  ClearBatchStream;
end;

procedure TDataStoreClient.DeleteData(dbN: SystemString; dStorePos: Int64);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteInt64(dStorePos);
  SendTunnel.SendDirectStreamCmd(C_DeleteData, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.FastPostCompleteBuffer(dbN: SystemString; stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean);
var
  p: Pointer;
  siz: nativeUInt;
begin
  p := EncodeOneBuff(dbN, dID, 0, stream.Memory, stream.Size, siz);
  SendTunnel.SendCompleteBuffer(C_FastPostCompleteBuffer, p, siz, True);

  if DoneTimeFree then
      DisposeObject(stream);
end;

procedure TDataStoreClient.FastPostCompleteBufferCopy(dbN: SystemString; stream: TCoreClassStream; dID: Cardinal);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  stream.Position := 0;
  M.CopyFrom(stream, stream.Size);
  M.Position := 0;
  FastPostCompleteBuffer(dbN, M, dID, True);
end;

procedure TDataStoreClient.FastPostCompleteBuffer(dbN: SystemString; DataSource: TDataFrameEngine);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.EncodeTo(M, True);
  FastPostCompleteBuffer(dbN, M, c_DF, True);
end;

procedure TDataStoreClient.FastPostCompleteBuffer(dbN: SystemString; DataSource: THashVariantList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  FastPostCompleteBuffer(dbN, M, c_VL, True);
end;

procedure TDataStoreClient.FastPostCompleteBuffer(dbN: SystemString; DataSource: THashStringList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  FastPostCompleteBuffer(dbN, M, c_VT, True);
end;

procedure TDataStoreClient.FastPostCompleteBuffer(dbN: SystemString; DataSource: TSectionTextData);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  FastPostCompleteBuffer(dbN, M, c_TE, True);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.FastPostCompleteBuffer(dbN: SystemString; DataSource: TJsonObject);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  FastPostCompleteBuffer(dbN, M, c_Json, True);
end;
{$ENDIF}


procedure TDataStoreClient.FastPostCompleteBuffer(dbN: SystemString; DataSource: TPascalString);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, M);
  FastPostCompleteBuffer(dbN, M, c_PascalString, True);
end;

procedure TDataStoreClient.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean);
var
  p: Pointer;
  siz: nativeUInt;
begin
  p := EncodeOneBuff(dbN, dID, dStorePos, stream.Memory, stream.Size, siz);
  SendTunnel.SendCompleteBuffer(C_FastInsertCompleteBuffer, p, siz, True);

  if DoneTimeFree then
      DisposeObject(stream);
end;

procedure TDataStoreClient.FastInsertCompleteBufferCopy(dbN: SystemString; dStorePos: Int64; stream: TCoreClassStream; dID: Cardinal);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  stream.Position := 0;
  M.CopyFrom(stream, stream.Size);
  M.Position := 0;
  FastInsertCompleteBuffer(dbN, dStorePos, M, dID, True);
end;

procedure TDataStoreClient.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.EncodeTo(M, True);
  FastInsertCompleteBuffer(dbN, dStorePos, M, c_DF, True);
end;

procedure TDataStoreClient.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  FastInsertCompleteBuffer(dbN, dStorePos, M, c_VL, True);
end;

procedure TDataStoreClient.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashStringList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  FastInsertCompleteBuffer(dbN, dStorePos, M, c_VT, True);
end;

procedure TDataStoreClient.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  FastInsertCompleteBuffer(dbN, dStorePos, M, c_TE, True);
end;

{$IFNDEF FPC} procedure TDataStoreClient.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M, False, TEncoding.UTF8, True);
  FastInsertCompleteBuffer(dbN, dStorePos, M, c_Json, True);
end;
{$ENDIF}


procedure TDataStoreClient.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, M);
  FastInsertCompleteBuffer(dbN, dStorePos, M, c_PascalString, True);
end;

procedure TDataStoreClient.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean);
var
  p: Pointer;
  siz: nativeUInt;
begin
  p := EncodeOneBuff(dbN, dID, dStorePos, stream.Memory, stream.Size, siz);
  SendTunnel.SendCompleteBuffer(C_FastModifyCompleteBuffer, p, siz, True);

  if DoneTimeFree then
      DisposeObject(stream);
end;

procedure TDataStoreClient.FastModifyCompleteBufferCopy(dbN: SystemString; dStorePos: Int64; stream: TCoreClassStream; dID: Cardinal);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  stream.Position := 0;
  M.CopyFrom(stream, stream.Size);
  M.Position := 0;
  FastModifyCompleteBuffer(dbN, dStorePos, M, dID, True);
end;

procedure TDataStoreClient.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.EncodeTo(M, True);
  FastModifyCompleteBuffer(dbN, dStorePos, M, c_DF, True);
end;

procedure TDataStoreClient.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  FastModifyCompleteBuffer(dbN, dStorePos, M, c_VL, True);
end;

procedure TDataStoreClient.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashStringList);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  FastModifyCompleteBuffer(dbN, dStorePos, M, c_VT, True);
end;

procedure TDataStoreClient.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M);
  FastModifyCompleteBuffer(dbN, dStorePos, M, c_TE, True);
end;

{$IFNDEF FPC} procedure TDataStoreClient.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  DataSource.SaveToStream(M, False, TEncoding.UTF8, True);
  FastModifyCompleteBuffer(dbN, dStorePos, M, c_Json, True);
end;
{$ENDIF}


procedure TDataStoreClient.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString);
var
  M: TMemoryStream64;
begin
  M := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, M);
  FastModifyCompleteBuffer(dbN, dStorePos, M, c_PascalString, True);
end;

procedure TDataStoreClient.GetDBListM(OnResult: TStreamMethod);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  SendTunnel.SendStreamCmdM(C_GetDBList, de, OnResult);
  DisposeObject(de);
end;

procedure TDataStoreClient.GetQueryListM(OnResult: TStreamMethod);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  SendTunnel.SendStreamCmdM(C_GetQueryList, de, OnResult);
  DisposeObject(de);
end;

procedure TDataStoreClient.GetQueryStateM(pipeN: SystemString; OnResult: TStreamMethod);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipeN);
  SendTunnel.SendStreamCmdM(C_GetQueryState, de, OnResult);
  DisposeObject(de);
end;

procedure TDataStoreClient.QueryStop(pipeN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipeN);
  SendTunnel.SendDirectStreamCmd(C_QueryStop, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.QueryPause(pipeN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipeN);
  SendTunnel.SendDirectStreamCmd(C_QueryPause, de);
  DisposeObject(de);
end;

procedure TDataStoreClient.QueryPlay(pipeN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipeN);
  SendTunnel.SendDirectStreamCmd(C_QueryPlay, de);
  DisposeObject(de);
end;

{$IFNDEF FPC}


procedure TDataStoreClient.GetDBListP(OnResult: TStreamProc);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  SendTunnel.SendStreamCmdP(C_GetDBList, de, OnResult);
  DisposeObject(de);
end;

procedure TDataStoreClient.GetQueryListP(OnResult: TStreamProc);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  SendTunnel.SendStreamCmdP(C_GetQueryList, de, OnResult);
  DisposeObject(de);
end;

procedure TDataStoreClient.GetQueryStateP(pipeN: SystemString; OnResult: TStreamProc);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipeN);
  SendTunnel.SendStreamCmdP(C_GetQueryState, de, OnResult);
  DisposeObject(de);
end;
{$ENDIF}

end.

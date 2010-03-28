object dmMain: TdmMain
  OldCreateOrder = False
  Left = 282
  Top = 340
  Height = 357
  Width = 601
  object bshMain: TBoldSystemHandle
    IsDefault = True
    SystemTypeInfoHandle = stiMain
    Active = False
    PersistenceHandle = HISBoldTCPPropagator1
    Left = 128
    Top = 152
  end
  object stiMain: TBoldSystemTypeInfoHandle
    BoldModel = bmoMain
    Left = 236
    Top = 76
  end
  object bmoMain: TBoldModel
    UMLModelMode = ummNone
    Boldify.EnforceDefaultUMLCase = False
    Boldify.DefaultNavigableMultiplicity = '0..1'
    Boldify.DefaultNonNavigableMultiplicity = '0..*'
    Left = 124
    Top = 16
    Model = (
      'VERSION 19'
      '(Model'
      #9'"BoldTCPDemoModel"'
      #9'"RootClass"'
      #9'""'
      #9'""'
      
        #9'"_BoldInternal.flattened=True,_Boldify.boldified=True,_BoldInte' +
        'rnal.ModelErrors=,Bold.DelphiName=<Name>,Bold.GenerateMultiplici' +
        'tyConstraints=False,Bold.ImplementationUses=dMain,Bold.UnitName=' +
        'BoldTCPDemoBoldClasses,Bold.RootClass=RootClass,Bold.UseXFiles=F' +
        'alse,Bold.UseTimestamp=False,Bold.UseGlobalId=False,Bold.UseRead' +
        'Only=False,Bold.UseClockLog=False,Bold.GenerateDefaultRegions=Tr' +
        'ue"'
      #9'(Classes'
      #9#9'(Class'
      #9#9#9'"RootClass"'
      #9#9#9'"<NONE>"'
      #9#9#9'TRUE'
      #9#9#9'FALSE'
      #9#9#9'""'
      #9#9#9'""'
      #9#9#9'"persistence=persistent"'
      #9#9#9'(Attributes'
      #9#9#9')'
      #9#9#9'(Methods'
      #9#9#9')'
      #9#9')'
      #9#9'(Class'
      #9#9#9'"Books"'
      #9#9#9'"RootClass"'
      #9#9#9'TRUE'
      #9#9#9'FALSE'
      #9#9#9'""'
      #9#9#9'""'
      
        #9#9#9'"persistence=persistent,\"Bold.DefaultStringRepresentation=bo' +
        'okID.asString + '#39':'#39' + title\""'
      #9#9#9'(Attributes'
      #9#9#9#9'(Attribute'
      #9#9#9#9#9'"Title"'
      #9#9#9#9#9'"String"'
      #9#9#9#9#9'FALSE'
      #9#9#9#9#9'""'
      #9#9#9#9#9'""'
      #9#9#9#9#9'2'
      #9#9#9#9#9'""'
      #9#9#9#9#9'"derived=False,persistence=persistent"'
      #9#9#9#9')'
      #9#9#9#9'(Attribute'
      #9#9#9#9#9'"Author"'
      #9#9#9#9#9'"String"'
      #9#9#9#9#9'FALSE'
      #9#9#9#9#9'""'
      #9#9#9#9#9'""'
      #9#9#9#9#9'2'
      #9#9#9#9#9'""'
      #9#9#9#9#9'"derived=False,persistence=persistent"'
      #9#9#9#9')'
      #9#9#9#9'(Attribute'
      #9#9#9#9#9'"BookID"'
      #9#9#9#9#9'"Integer"'
      #9#9#9#9#9'FALSE'
      #9#9#9#9#9'""'
      #9#9#9#9#9'""'
      #9#9#9#9#9'2'
      #9#9#9#9#9'""'
      #9#9#9#9#9'"derived=False,persistence=persistent"'
      #9#9#9#9')'
      #9#9#9')'
      #9#9#9'(Methods'
      #9#9#9#9'(Method'
      #9#9#9#9#9'"PrepareDelete"'
      #9#9#9#9#9'""'
      #9#9#9#9#9'FALSE'
      #9#9#9#9#9'""'
      #9#9#9#9#9'""'
      #9#9#9#9#9'2'
      #9#9#9#9#9'""'
      #9#9#9#9#9'"Bold.OperationKind=Override"'
      #9#9#9#9')'
      #9#9#9#9'(Method'
      #9#9#9#9#9'"ReceiveQueryFromOwned"'
      
        #9#9#9#9#9'"Originator: TObject; OriginalEvent: TBoldEvent; const Args' +
        ': array of const; Subscriber: TBoldSubscriber"'
      #9#9#9#9#9'FALSE'
      #9#9#9#9#9'"Boolean"'
      #9#9#9#9#9'""'
      #9#9#9#9#9'2'
      #9#9#9#9#9'""'
      #9#9#9#9#9'"Bold.OperationKind=Override"'
      #9#9#9#9')'
      #9#9#9')'
      #9#9')'
      #9#9'(Class'
      #9#9#9'"NextNumberGenerator"'
      #9#9#9'"RootClass"'
      #9#9#9'TRUE'
      #9#9#9'FALSE'
      #9#9#9'""'
      #9#9#9'""'
      #9#9#9'"persistence=persistent"'
      #9#9#9'(Attributes'
      #9#9#9#9'(Attribute'
      #9#9#9#9#9'"LastNumberUsed"'
      #9#9#9#9#9'"Integer"'
      #9#9#9#9#9'FALSE'
      #9#9#9#9#9'""'
      #9#9#9#9#9'""'
      #9#9#9#9#9'2'
      #9#9#9#9#9'""'
      #9#9#9#9#9'"derived=False,persistence=persistent"'
      #9#9#9#9')'
      #9#9#9')'
      #9#9#9'(Methods'
      #9#9#9#9'(Method'
      #9#9#9#9#9'"Instance"'
      #9#9#9#9#9'""'
      #9#9#9#9#9'TRUE'
      #9#9#9#9#9'"TNextNumberGenerator"'
      #9#9#9#9#9'""'
      #9#9#9#9#9'2'
      #9#9#9#9#9'""'
      #9#9#9#9#9'""'
      #9#9#9#9')'
      #9#9#9#9'(Method'
      #9#9#9#9#9'"NextNumber"'
      #9#9#9#9#9'""'
      #9#9#9#9#9'FALSE'
      #9#9#9#9#9'"Integer"'
      #9#9#9#9#9'""'
      #9#9#9#9#9'2'
      #9#9#9#9#9'""'
      #9#9#9#9#9'""'
      #9#9#9#9')'
      #9#9#9')'
      #9#9')'
      #9#9'(Class'
      #9#9#9'"ReturnedNumbers"'
      #9#9#9'"RootClass"'
      #9#9#9'TRUE'
      #9#9#9'FALSE'
      #9#9#9'""'
      #9#9#9'""'
      #9#9#9'"persistence=persistent"'
      #9#9#9'(Attributes'
      #9#9#9#9'(Attribute'
      #9#9#9#9#9'"ReturnedNumber"'
      #9#9#9#9#9'"Integer"'
      #9#9#9#9#9'FALSE'
      #9#9#9#9#9'""'
      #9#9#9#9#9'""'
      #9#9#9#9#9'2'
      #9#9#9#9#9'""'
      #9#9#9#9#9'"derived=False,persistence=persistent"'
      #9#9#9#9')'
      #9#9#9#9'(Attribute'
      #9#9#9#9#9'"Reason"'
      #9#9#9#9#9'"String"'
      #9#9#9#9#9'FALSE'
      #9#9#9#9#9'""'
      #9#9#9#9#9'""'
      #9#9#9#9#9'2'
      #9#9#9#9#9'""'
      #9#9#9#9#9'"derived=False,persistence=persistent"'
      #9#9#9#9')'
      #9#9#9')'
      #9#9#9'(Methods'
      #9#9#9')'
      #9#9')'
      #9')'
      #9'(Associations'
      #9#9'(Association'
      #9#9#9'"NumbersReturn"'
      #9#9#9'"<NONE>"'
      #9#9#9'""'
      #9#9#9'""'
      #9#9#9'"derived=False,persistence=persistent,Bold.DelphiName=<Name>"'
      #9#9#9'FALSE'
      #9#9#9'(Roles'
      #9#9#9#9'(Role'
      #9#9#9#9#9'"Returned"'
      #9#9#9#9#9'TRUE'
      #9#9#9#9#9'TRUE'
      #9#9#9#9#9'"NextNumberGenerator"'
      #9#9#9#9#9'""'
      #9#9#9#9#9'"0..*"'
      #9#9#9#9#9'""'
      #9#9#9#9#9'0'
      #9#9#9#9#9'2'
      #9#9#9#9#9'0'
      #9#9#9#9#9'"Bold.Embed=False"'
      #9#9#9#9#9'(Qualifiers'
      #9#9#9#9#9')'
      #9#9#9#9')'
      #9#9#9#9'(Role'
      #9#9#9#9#9'"NumberGenerator"'
      #9#9#9#9#9'TRUE'
      #9#9#9#9#9'FALSE'
      #9#9#9#9#9'"ReturnedNumbers"'
      #9#9#9#9#9'""'
      #9#9#9#9#9'"1..1"'
      #9#9#9#9#9'""'
      #9#9#9#9#9'0'
      #9#9#9#9#9'2'
      #9#9#9#9#9'0'
      #9#9#9#9#9'""'
      #9#9#9#9#9'(Qualifiers'
      #9#9#9#9#9')'
      #9#9#9#9')'
      #9#9#9')'
      #9#9')'
      #9')'
      ')')
  end
  object ActionList1: TActionList
    Left = 128
    Top = 240
    object BoldUpdateDBAction1: TBoldUpdateDBAction
      Category = 'Bold Actions'
      Caption = 'Update DB'
      BoldSystemHandle = bshMain
    end
    object BoldActivateSystemAction1: TBoldActivateSystemAction
      Category = 'Bold Actions'
      Caption = 'Open system'
      BoldSystemHandle = bshMain
      OpenCaption = 'Open system'
      CloseCaption = 'Close system'
      SaveQuestion = 'There are dirty objects. Save them before closing system?'
      SaveOnClose = saAsk
    end
    object BoldIBDatabaseAction1: TBoldIBDatabaseAction
      Category = 'Bold Actions'
      Caption = 'Create DB'
      BoldSystemHandle = bshMain
      Username = 'SYSDBA'
      Password = 'masterkey'
    end
  end
  object BoldPersistenceHandleDB1: TBoldPersistenceHandleDB
    BoldModel = bmoMain
    ClockLogGranularity = '0:0:0.0'
    DatabaseAdapter = BoldDatabaseAdapterIB1
    Left = 48
    Top = 104
  end
  object BoldDatabaseAdapterIB1: TBoldDatabaseAdapterIB
    SQLDatabaseConfig.ColumnTypeForDate = 'TIMESTAMP'
    SQLDatabaseConfig.ColumnTypeForTime = 'TIMESTAMP'
    SQLDatabaseConfig.ColumnTypeForDateTime = 'TIMESTAMP'
    SQLDatabaseConfig.ColumnTypeForBlob = 'BLOB'
    SQLDatabaseConfig.ColumnTypeForFloat = 'DOUBLE PRECISION'
    SQLDatabaseConfig.ColumnTypeForCurrency = 'DOUBLE PRECISION'
    SQLDatabaseConfig.ColumnTypeForString = 'VARCHAR(%d)'
    SQLDatabaseConfig.ColumnTypeForInteger = 'INTEGER'
    SQLDatabaseConfig.ColumnTypeForSmallInt = 'SMALLINT'
    SQLDatabaseConfig.DropColumnTemplate = 'ALTER TABLE <TableName> DROP <ColumnName>'
    SQLDatabaseConfig.DropTableTemplate = 'DROP TABLE <TableName>'
    SQLDatabaseConfig.DropIndexTemplate = 'DROP INDEX <IndexName>'
    SQLDatabaseConfig.MaxDbIdentifierLength = 31
    SQLDatabaseConfig.MaxIndexNameLength = 31
    SQLDatabaseConfig.SQLforNotNull = 'NOT NULL'
    SQLDatabaseConfig.QuoteNonStringDefaultValues = False
    SQLDatabaseConfig.SupportsConstraintsInCreateTable = True
    SQLDatabaseConfig.SupportsStringDefaultValues = True
    SQLDatabaseConfig.DBGenerationMode = dbgQuery
    SQLDatabaseConfig.ReservedWords.Strings = (
      'ACTIVE, ADD, ALL, AFTER, ALTER'
      'AND, ANY, AS, ASC, ASCENDING,'
      'AT, AUTO, AUTOINC, AVG, BASE_NAME'
      'BEFORE, BEGIN, BETWEEN, BLOB, BOOLEAN,'
      'BOTH, BY, BYTES, CACHE, CAST, CHAR'
      'CHARACTER, CHECK, CHECK_POINT_LENGTH, COLLATE,'
      'COLUMN, COMMIT, COMMITTED, COMPUTED'
      'CONDITIONAL, CONSTRAINT, CONTAINING, COUNT, CREATE, CSTRING,'
      'CURRENT, CURSOR, DATABASE, DATE, DAY'
      'DEBUG, DEC, DECIMAL, DECLARE, DEFAULT,'
      'DELETE, DESC, DESCENDING, DISTINCT, DO'
      'DOMAIN, DOUBLE, DROP, ELSE, END,'
      'ENTRY_POINT, ESCAPE, EXCEPTION, EXECUTE'
      'EXISTS, EXIT, EXTERNAL, EXTRACT, FILE, FILTER,'
      'FLOAT, FOR, FOREIGN, FROM, FULL, FUNCTION'
      'GDSCODE, GENERATOR, GEN_ID, GRANT,'
      'GROUP, GROUP_COMMIT_WAIT_TIME, HAVING'
      'HOUR, IF, IN, INT, INACTIVE, INDEX, INNER,'
      'INPUT_TYPE, INSERT, INTEGER, INTO'
      'IS, ISOLATION, JOIN, KEY, LONG, LENGTH,'
      'LOGFILE, LOWER, LEADING, LEFT, LEVEL'
      'LIKE, LOG_BUFFER_SIZE, MANUAL, MAX, MAXIMUM_SEGMENT,'
      'MERGE, MESSAGE, MIN, MINUTE, MODULE_NAME'
      'MONEY, MONTH, NAMES, NATIONAL, NATURAL,'
      'NCHAR, NO, NOT, NULL, NUM_LOG_BUFFERS'
      'NUMERIC, OF, ON, ONLY, OPTION,'
      'OR, ORDER, OUTER, OUTPUT_TYPE, OVERFLOW'
      'PAGE_SIZE, PAGE, PAGES, PARAMETER, PASSWORD,'
      'PLAN, POSITION, POST_EVENT, PRECISION'
      
        'PROCEDURE, PROTECTED, PRIMARY, PRIVILEGES, RAW_PARTITIONS, RDB$D' +
        'B_KEY,'
      'READ, REAL, RECORD_VERSION, REFERENCES'
      'RESERV, RESERVING, RETAIN, RETURNING_VALUES, RETURNS, REVOKE,'
      'RIGHT, ROLE, ROLLBACK, SECOND, SEGMENT'
      'SELECT, SET, SHARED, SHADOW, SCHEMA, SINGULAR,'
      'SIZE, SMALLINT, SNAPSHOT, SOME, SORT'
      'SQLCODE, STABILITY, STARTING, STARTS, STATISTICS,'
      'SUB_TYPE, SUBSTRING, SUM, SUSPEND, TABLE'
      'THEN, TIME, TIMESTAMP, TIMEZONE_HOUR, TIMEZONE_MINUTE,'
      'TO, TRAILING, TRANSACTION, TRIGGER, TRIM'
      'UNCOMMITTED, UNION, UNIQUE, UPDATE, UPPER,'
      'USER, VALUE, VALUES, VARCHAR, VARIABLE'
      'VARYING, VIEW, WAIT, WHEN, WHERE,'
      'WHILE, WITH, WORK, WRITE, YEAR')
    SQLDatabaseConfig.StoreEmptyStringsAsNULL = False
    SQLDatabaseConfig.SystemTablePrefix = 'BOLD'
    SQLDatabaseConfig.SqlScriptSeparator = '---'
    SQLDatabaseConfig.SqlScriptTerminator = ';'
    SQLDatabaseConfig.SqlScriptCommentStart = '/* '
    SQLDatabaseConfig.SqlScriptCommentStop = ' */'
    SQLDatabaseConfig.SqlScriptStartTransaction = 'START TRANSACTION'
    SQLDatabaseConfig.SqlScriptCommitTransaction = 'COMMIT'
    SQLDatabaseConfig.SqlScriptRollBackTransaction = 'ROLLBACK'
    DataBase = IBDatabase1
    DatabaseEngine = dbeInterbaseSQLDialect3
    Left = 48
    Top = 160
  end
  object IBDatabase1: TIBDatabase
    Params.Strings = (
      'user_name=sysdba'
      'password=masterkey')
    LoginPrompt = False
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 208
  end
  object HISBoldTCPPropagator1: THISBoldTCPPropagator
    ClientIDString = '<Name>'
    NextPersistenceHandle = BoldPersistenceHandleDB1
    Active = False
    Dequeuer = BoldExternalObjectSpaceEventHandler1
    SystemHandle = bshMain
    Locking = True
    Left = 272
    Top = 248
  end
  object BoldExternalObjectSpaceEventHandler1: TBoldExternalObjectSpaceEventHandler
    BoldSystemHandle = bshMain
    Left = 264
    Top = 160
  end
end

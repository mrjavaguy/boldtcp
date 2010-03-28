object MonitorDM: TMonitorDM
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Left = 211
  Top = 177
  Height = 418
  Width = 408
  object cdsClients: TClientDataSet
    Aggregates = <>
    FieldDefs = <
      item
        Name = 'cdsClientsClientID'
        DataType = ftInteger
      end
      item
        Name = 'cdsClientsClientIDString'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'cdsClientsLeaseDuration'
        DataType = ftInteger
      end
      item
        Name = 'cdsClientsLeaseExpires'
        DataType = ftString
        Size = 20
      end>
    IndexDefs = <
      item
        Name = 'cdsClientsIndex1'
        Fields = 'cdsClientsClientID'
        Options = [ixPrimary, ixUnique]
      end>
    IndexName = 'cdsClientsIndex1'
    Params = <>
    StoreDefs = True
    Left = 48
    Top = 16
    object cdsClientscdsClientsClientID: TIntegerField
      DisplayLabel = 'Client ID'
      FieldName = 'cdsClientsClientID'
    end
    object cdsClientscdsClientsClientIDString: TStringField
      DisplayLabel = 'Name'
      FieldName = 'cdsClientsClientIDString'
    end
    object cdsClientscdsClientsLeaseDuration: TIntegerField
      DisplayLabel = 'Lease Duration'
      FieldName = 'cdsClientsLeaseDuration'
    end
    object cdsClientscdsClientsLeaseExpires: TStringField
      DisplayLabel = 'Lease Expires'
      FieldName = 'cdsClientsLeaseExpires'
    end
  end
  object dsClients: TDataSource
    DataSet = cdsClients
    Left = 128
    Top = 16
  end
  object IdTCPClientMonitor: TIdTCPClient
    MaxLineAction = maException
    ReadTimeout = 0
    Port = 0
    Left = 224
    Top = 16
  end
  object MonitorTimer: TTimer
    Enabled = False
    OnTimer = MonitorTimerTimer
    Left = 56
    Top = 88
  end
end

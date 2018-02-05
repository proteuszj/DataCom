object DM: TDM
  OldCreateOrder = False
  Height = 238
  Width = 318
  object OracleUniProvider: TOracleUniProvider
    Left = 40
    Top = 24
  end
  object DBConnect: TUniConnection
    AutoCommit = False
    ProviderName = 'Oracle'
    SpecificOptions.Strings = (
      'Oracle.Direct=True'
      'Oracle.Charset=ZHS16GBK'
      'Oracle.UnicodeEnvironment=True'
      'Oracle.UseUnicode=True'
      'Oracle.ConnectionTimeout=10')
    Options.AllowImplicitConnect = False
    Options.KeepDesignConnected = False
    Username = 'tnzc_dz'
    Server = '192.168.1.101:1521'
    LoginPrompt = False
    Left = 136
    Top = 24
    EncryptedPassword = 'ABFF91FFDBFF85FF9CFFA0FFCEFFC9FFCFFFC9FFCEFFCFFF'
  end
  object pubQuery: TUniQuery
    Connection = DBConnect
    Left = 224
    Top = 24
  end
  object spSql: TUniStoredProc
    Connection = DBConnect
    Left = 32
    Top = 80
  end
end

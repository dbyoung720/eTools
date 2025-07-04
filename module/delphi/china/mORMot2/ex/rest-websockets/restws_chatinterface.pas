unit restws_chatinterface;

interface

uses
  mormot.core.base,
  mormot.core.interfaces, // for TInterfaceFactory.RegisterInterfaces
  mormot.soa.core;        // for IServiceWithCallbackReleased

type
  IChatCallback = interface(IInvokable)
    ['{EA7EFE51-3EBA-4047-A356-253374518D1D}']
    procedure NotifyBlaBla(const pseudo, msg: string);
  end;

  IChatService = interface(IServiceWithCallbackReleased)
    ['{C92DCBEA-C680-40BD-8D9C-3E6F2ED9C9CF}']
    procedure Join(const pseudo: string; const callback: IChatCallback);
    procedure BlaBla(const pseudo, msg: string);
  end;

const
  CHAT_TRANSMISSION_KEY = 'meow_privatekey';

  
implementation

initialization
  TInterfaceFactory.RegisterInterfaces([
    TypeInfo(IChatCallback),
    TypeInfo(IChatService)
    ]);
end.

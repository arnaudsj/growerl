%%% File    : growl.erl
%%% Author  : Sébastien Arnaud <arnaudsj@gmail.com>
%%% Description : 
%%% First Created : 27 Jan 2009 by Sébastien Arnaud <arnaudsj@gmail.com>

-module(growl).

-author("Sébastien Arnaud <arnaudsj@gmail.com>").

-include("../include/growl.hrl").
-compile(export_all).

% ver %
-define(GROWL_PROTOCOL_VERSION, 1).
-define(GROWL_PROTOCOL_VERSION_AES128, 2).

% type %
-define(GROWL_TYPE_REGISTRATION, 0).        %registration packets with MD5 authentication%
-define(GROWL_TYPE_NOTIFICATION, 1).        %notification packets with MD5 authentication%
-define(GROWL_TYPE_REGISTRATION_SHA256, 2). %registration packets with SHA-256 authentication%
-define(GROWL_TYPE_NOTIFICATION_SHA256, 3). %notification packets with SHA-256 authentication%
-define(GROWL_TYPE_REGISTRATION_NOAUTH, 4). %registration packets without authentication%
-define(GROWL_TYPE_NOTIFICATION_NOAUTH, 5). %notification packets without authentication%

% defaults %
-define(GROWL_UDP_PORT, 9887).
-define(GROWL_APPNAME, "GrowlNotify in Erlang").
-define(GROWL_PASSWORD, "").

% start
start()-> 
	?MODULE:register(?GROWL_APPNAME,?GROWL_PASSWORD),
	Message = #message{title="Hello World", description="This notification was sent from Erlang!"},
	?MODULE:notify(Message, ?GROWL_APPNAME, ?GROWL_PASSWORD).
	
% Notify
notify(Message, Appname, Password, GrowlIP, GrowlUDPPort) ->
	{ok, S}= gen_udp:open(48889),
	ok = gen_udp:send(S, GrowlIP, GrowlUDPPort, notification_packet(Message, Appname, Password)),
	ok = gen_udp:close(S).	


notification_packet(Message, Appname, Password) ->
	A = list_to_binary(to_utf8(Appname)),
	L = size(A),
	P = << ?GROWL_PROTOCOL_VERSION:8, ?GROWL_TYPE_NOTIFICATION:8, L:16, 1:8, 1:8, A/binary, 0:16, 0:8 >>,
	sign_packet(P,Password).	



% Register an app
register(Appname)->
	register(Appname, "", {127,0,0,1}, ?GROWL_UDP_PORT).
	
register(Appname, Password)->
		register(Appname, Password, {127,0,0,1}, ?GROWL_UDP_PORT).
		
register(Appname, Password, GrowlIP)->
	register(Appname, Password, GrowlIP, ?GROWL_UDP_PORT).
		
register(Appname, Password, GrowlIP, GrowlUDPPort)->
	{ok, S}= gen_udp:open(48888),
	ok = gen_udp:send(S,GrowlIP,GrowlUDPPort,registration_packet(Appname,Password)),
	ok = gen_udp:close(S).

% Registration packet
registration_packet(Appname,Password)->
	A = list_to_binary(to_utf8(Appname)),
	L = size(A),
	P = << ?GROWL_PROTOCOL_VERSION:8, ?GROWL_TYPE_REGISTRATION:8, L:16, 1:8, 1:8, A/binary, 0:16, 0:8 >>,
	sign_packet(P,Password).

% Sign Growl packet
% TODO: look at the GROWL_TYPE to decide which signature to use (MD5 | SHA-256 | NONE)
sign_packet(P,Password)->
	Pwd = list_to_binary(to_utf8(Password)),
	C = erlang:md5(<<P/binary, Pwd/binary>>),
	<< P/binary, C/binary >>.

% to_utf8 util function
to_utf8([H|T]) when H < 16#80 -> [H | to_utf8(T)];                                                                 
to_utf8([H|T]) when H < 16#C0 -> [16#C2,H | to_utf8(T)];                                                           
to_utf8([H|T])                -> [16#C3, H-64 | to_utf8(T)];                                                       
to_utf8([])                   -> [].

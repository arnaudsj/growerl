-module(iso_8859_1).
-export([to_utf8/1]).

to_utf8([H|T]) when H < 16#80 -> [H | to_utf8(T)];                                                                 
to_utf8([H|T]) when H < 16#C0 -> [16#C2,H | to_utf8(T)];                                                           
to_utf8([H|T])                -> [16#C3, H-64 | to_utf8(T)];                                                       
to_utf8([])                   -> [].
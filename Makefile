compile:
	erl -make
	
clean:
	rm -rf ./ebin/*.*

test: compile
	erl -noshell -pa ./ebin -s growl test -s init stop
	
doc:
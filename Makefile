default:
	echo "make test to build and test"
	exit 1

test_hello:
	erl -noshell -s hello hello_world -s init stop

echat.beam: echat.erl
	echo 'c(echat).' | erl

test: echat.beam
	erl -noshell -s echat run

test:
	for number in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21; do \
		./flp22-log.pl "tests/$$number.txt" > testOut.txt || true && \
		diff testOut.txt "testsExpected/$$number.txt" && \
		echo "test $$number pass" && \
		rm testOut.txt; \
	done


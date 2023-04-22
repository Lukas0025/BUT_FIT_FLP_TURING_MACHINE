test:
	for number in 1 2 3 4 5 ; do \
		./flp22-log.pl "tests/$$number.txt" > testOut.txt && \
		diff testOut.txt "testsExpected/$$number.txt" && \
		echo "test $$number pass" && \
		rm testOut.txt; \
	done


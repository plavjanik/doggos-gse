       PROCESS PGMN(LM),NODYNAM
      ******************************************************************
      * The above process option is required for long entry point      *
      * names and locating the entry points. These options should not  *
      * be changed.                                                    *
      ******************************************************************
      ******************************************************************
      * This test suite contains a set of tests meant to show how the  *
      * Test4z API can be used. It is not meant to be exhaustive       *
      * but instead show patterns of usage and code organization.      *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. 'ZTTDOGOS' RECURSIVE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      ******************************************************************
      * Copy in our required control blocks from Test4z.               *
      ******************************************************************
       COPY ZTESTWS.

      ******************************************************************
      * Define any working-storage items that we need.                 *
      ******************************************************************

      * Test4z File object that will contain ADOPT input records
       1 ADOPTS_FILE.
         COPY ZFILE.

      * Input data used to initialize above file.
       1 ADOPT_INPUT.
         3 MY_Data.
           5 filler.
               7 pic x(30) value 'SHIBA'.
               7 pic x(25) value SPACES.
               7 pic x(3) value '006'.
           5 filler.
               7 pic x(30) value 'KORGI'.
               7 pic x(25) value SPACES.
               7 pic x(3) value '007'.
           5 filler.
               7 pic x(30) value 'CHI'.
               7 pic x(25) value SPACES.
               7 pic x(3) value '001'.
           5 filler.
               7 pic x(30) value 'SHIBA'.
               7 pic x(25) value SPACES.
               7 pic x(3) value '002'.
           5 filler.
               7 pic x(30) value 'JINGO'.
               7 pic x(25) value SPACES.
               7 pic x(3) value '006'.

      * Test4z QSAM file access mock object for ADOPTS DD.
      * Used to access ADOPTS_FILE records.
       1 ADOPTS.
         COPY ZQSAM.

      * Test4z QSAM file access mock object for OUTREP DD.
      * Only used for output so no need to separately create
      * file with input records - the file written to is created
      * automatically.
       1 OUTREP.
         COPY ZQSAM.

      * Variable given on registration of 'ForceErrorSpy' callback.
       1 IO_command pic x(10).

      * Loop counter
       1 i pic 9(9) comp-5.

      * List ptr for looping through lists
      * record_int allows for pointer arithmetic
       1 record_ptr usage pointer.
       1 record_int redefines record_ptr pic s9(9) comp-5.

       LINKAGE SECTION.
      ******************************************************************
      * Copy in our required control blocks from Test4z.               *
      ******************************************************************
       COPY ZTESTLS.

      * Report record used when accessing records written to OUTREP
       COPY ADOPTRPT.

      * Used in 'ForceErrorSpy' callback implementation to map
      * the given IO_COMMAND variable setup
       1 SPY_IO_COMMAND pic x(10).

      * Mapping of above pointer.  Used to validate values within
      * the ACCUMULATOR DOGGOS program variable at the time the
      * given spy callback is invoked.
       1 SPY_ACCUMULATOR.
           05 ADOPTIONS PIC 9(3) OCCURS 9 TIMES.

       1 mystatuscode PIC x(2).

       PROCEDURE DIVISION.
      ******************************************************************
      * Register a set of tests to be run.                             *
      * Each I_Test invocation registers a name and test               *
      * implementation to be executed.                                 *
      * The given name for each test will be reported with a PASS/FAIL *
      ******************************************************************
           move low-values to I_Test
           set testFunction in ZWS_Test to entry 'test1'
           move 'DOGGOS simple run' to testName in ZWS_Test
           call ZTESTUT using ZWS_Test

           move low-values to I_Test
           set testFunction in ZWS_Test to entry 'test2'
           move 'DOGGOS validate accumulator' to testName in ZWS_Test
           call ZTESTUT using ZWS_Test

           move low-values to I_Test
           set testFunction in ZWS_Test to entry 'test3'
           move 'DOGGOS force OPEN error' to testName in ZWS_Test
           call ZTESTUT using ZWS_Test

           move low-values to I_Test
           set testFunction in ZWS_Test to entry 'test4'
           move 'DOGGOS force READ error' to testName in ZWS_Test
           call ZTESTUT using ZWS_Test


           goback.

      ******************************************************************
      * Implementation for TEST1
      ******************************************************************
           entry 'test1'
      *    Mock all external resources
           perform mockADOPTSFile
           perform mockOUTREPFile
      *    Prepare and execute the DOGGOS program under test
           perform runDOGGOS
      *    Print the results written to the OUTREP file
           perform printReport
           goback.

      ******************************************************************
      * Implementation for TEST2
      ******************************************************************
           entry 'test2'
           perform mockADOPTSFile
           perform mockOUTREPFile
      * Register the CheckAccumulatorSpy callback which will
      * validate that all the values in the ACCUMULATOR DOGGOS
      * program variable are correct.
           perform registerCheckAccumulatorSpy
           perform runDOGGOS
           goback.

      ******************************************************************
      * Spy callback implementation for checking values in accumulator
      * This callback is registered by the 'registerCheckAccumulatorSpy'
      * call seen above.
      ******************************************************************
           entry 'CheckAccumulatorSpy' using
               ZLS_goBlock, ZLS_Q_itBlock, ZLS_Q_ifBlock

      *    A spy callback is called 4 times for each operation:
      *     - WHEN_BEFORE & SPY_BEFORE
      *     - WHEN_BEFORE & SPY_AFTER
      *     - WHEN_AFTER & SPY_BEFORE
      *     - WHEN_AFTER & SPY_AFTER
      *    Only process the last time for this callback
           if WHEN_AFTER in ZLS_Q_itBlock and SPY_AFTER in ZLS_Q_itBlock
              if commandName in ZLS_Q_itBlock = 'CLOSE'

      *         Access ACCUMULATOR variable in DOGGOS
      *         which results in the test linkage section variable
      *         SPY_ACCUMULATOR mapped onto the memory of that variable.
                move low-values to I_GetVariable
                move 'ACCUMULATOR' to variableName in ZWS_GetVariable
                call ZTESTUT using ZWS_GetVariable,
                    address of SPY_ACCUMULATOR

      *         Check accumulator values as assert correct values
      *         The 'fail_accumulator' will end the test with given
      *         message if the condition is false
                if adoptions(1) not = 8 perform fail_accumulator end-if
                if adoptions(2) not = 0 perform fail_accumulator end-if
                if adoptions(3) not = 7 perform fail_accumulator end-if
                if adoptions(4) not = 1 perform fail_accumulator end-if
                if adoptions(5) not = 0 perform fail_accumulator end-if
                if adoptions(6) not = 0 perform fail_accumulator end-if
                if adoptions(7) not = 0 perform fail_accumulator end-if
                if adoptions(8) not = 6 perform fail_accumulator end-if
                if adoptions(9) not = 0 perform fail_accumulator end-if
              end-if
           end-if
           goback.

      ******************************************************************
      * Implementation for TEST3
      ******************************************************************
           entry 'test3'
           perform mockADOPTSFile
           perform mockOUTREPFile
           move 'OPEN' to IO_COMMAND
           perform registerForceErrorSpy
           perform runDOGGOS
           goback.

      ******************************************************************
      * Implementation for TEST4
      ******************************************************************
           entry 'test4'
           perform mockADOPTSFile
           perform mockOUTREPFile
           move 'READ' to IO_COMMAND
           perform registerForceErrorSpy
           perform runDOGGOS
           goback.

      ******************************************************************
      * Spy callback implementation to force IO error paths.
      * Used by both TEST3 and TEST4. The registration of this
      * callback is done by PERFORM of 'registerForceErrorSpy' proc
      * in each of these tests.
      * Note the SPY_IO_COMMAND parameter which is the IO_COMMAND value
      * initially set up when this spy was registered
      ******************************************************************
           entry 'ForceErrorSpy' using
               ZLS_goBlock, ZLS_Q_itBlock, ZLS_Q_ifBlock,
               SPY_IO_COMMAND

      *    A spy callback is called 4 times for each operation:
      *     - WHEN_BEFORE & SPY_BEFORE
      *     - WHEN_BEFORE & SPY_AFTER
      *     - WHEN_AFTER & SPY_BEFORE
      *     - WHEN_AFTER & SPY_AFTER
      *    Only process the last time for this callback
           if WHEN_AFTER in ZLS_Q_itBlock and SPY_AFTER in ZLS_Q_itBlock
      *       Map the linkage section to the address of the last record.
              set address of mystatuscode to statuscode in ZLS_Q_ifBlock

      *       Check if the command that caused this callback to be
      *       invoked is the one we want to process on.
              if commandName in ZLS_Q_itBlock(1:4) = 'OPEN'
                 and SPY_IO_COMMAND = 'OPEN'
                 move '35' to mystatuscode
              else
                 if commandName in ZLS_Q_itBlock(1:4) = 'READ'
                    and SPY_IO_COMMAND = 'READ'
      *             Set error code on 5th READ
                    if (iteration in ZLS_Q_itBlock = 5)
                       move '46' to mystatuscode
                    end-if
                 end-if
               end-if
            end-if
           goback.


      ******************************************************************
      * Common proc to handle failed assertions about ACCUMULATOR values
      ******************************************************************
       fail_accumulator.
           move low-values to I_Assert in ZWS_Assert
           move 'Invalid accumulator value' to failMessage in ZWS_Assert
           call ZTESTUT using ZWS_Assert.

      ******************************************************************
      * Common proc to run DOGGOS program
      ******************************************************************
       runDOGGOS.
           move low-values to I_RunFunction
           move 'DOGGOS' to moduleName in ZWS_RunFunction
           call ZTESTUT using ZWS_RunFunction.

      ******************************************************************
      * Common proc to mock ADOPTS file
      ******************************************************************
       mockADOPTSFile.

      * Create a base file object containing ADOPTS input records.
           move low-values to I_File
           set recordAddress in ZWS_File to address of ADOPT_INPUT
           move 5 to recordCount in ZWS_File
           move 58 to recordSize in ZWS_File
           call ZTESTUT using ZWS_File, fileObject in ADOPTS_FILE

      * Initialize QSAM file access mock object for the ADOPTS DD
      * with the file object created above.
           move low-values to I_MockQSAM
           move 'ADOPTS' to fileName in ZWS_MockQSAM
           set fileObject in ZWS_MockQSAM to
               address of fileObject in ADOPTS_FILE
           call ZTESTUT using ZWS_MockQSAM, qsamObject in ADOPTS.

      ******************************************************************
      * Common proc to mock OUTREP QSAM output file.
      ******************************************************************
       mockOUTREPFile.
           move low-values to I_MockQSAM
           move 'OUTREP' to fileName in ZWS_MockQSAM
           move 58 to recordSize in ZWS_MockQSAM
           call ZTESTUT using ZWS_MockQSAM, qsamObject in OUTREP.

      ******************************************************************
      * Common proc to display contents of OUTREP file
      ******************************************************************
       printReport.
      *    set the address of our record pointer to
      *    the root address of our records in OUPREP file
           set record_ptr to ptr in records_ in file_ in OUTREP

      *    loop thru all the records and display each one
           perform varying i from 1 by 1 until
           not (i<=size_ in records_ in ADOPTS_FILE)
              set address of ADOPTED-REPORT-REC to record_ptr
              display ADOPTED-REPORT-REC

      *       Compute the next record pointer by adding the
      *       record stride (length) to the current record ptr
              add stride in records_ in ADOPTS_FILE to record_int
           end-perform.

      ******************************************************************
      * Register proc for 'ForceErrorSpy' callback on the ADOPTS DD.
      ******************************************************************
       registerCheckAccumulatorSpy.
           move low-values to I_LLRegisterSpy
           move 'DOGGOS' to moduleName in ZWS_LLRegisterSpy
           move 'ADOPTS' to artifactName in ZWS_LLRegisterSpy
           set interfaceTypeQSAM in ZWS_LLRegisterSpy to true
           set handler in ZWS_LLRegisterSpy
               to entry 'CheckAccumulatorSpy'
           call ZTESTUT using ZWS_LLRegisterSpy.


      ******************************************************************
      * Register proc for 'ForceErrorSpy' callback on the ADOPTS DD.
      * Used by both TEST3 and TEST4. Note the IO_COMMAND
      * variable given as part of the registration.  Every
      * invocation of the callback will pass along the address
      * of this variable.  The callback implementation can then
      * use this data for whatever purpose it wants.
      * In this usage the operation to force the
      * error upon (READ/OPEN) is setup by each test.
      ******************************************************************
       registerForceErrorSpy.
           move low-values to I_LLRegisterSpy
           move 'DOGGOS' to moduleName in ZWS_LLRegisterSpy
           move 'ADOPTS' to artifactName in ZWS_LLRegisterSpy
           set interfaceTypeQSAM in ZWS_LLRegisterSpy to true
           set handler in ZWS_LLRegisterSpy
               to entry 'ForceErrorSpy'
           set userData in ZWS_LLRegisterSpy to
               address of IO_COMMAND
           call ZTESTUT using ZWS_LLRegisterSpy.

       END PROGRAM 'ZTTDOGOS'.

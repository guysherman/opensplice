@ECHO OFF
mkdir  bld
mkdir  exec
cd bld
mkdir idlpp
mkdir classes
cd idlpp

REM
REM Generate java classes from IDL
REM
echo "Compile DurabilityData.idl"
idlpp -S -l java ../../../../../../idl/DurabilityData.idl

REM
REM Generate jacorb java classed from IDL
REM
echo "Compile DurabilityData.idl with JacORB IDL Compiler"
echo === java -classpath "%JACORB_HOME%\lib\idl.jar;%JACORB_HOME%\lib\endorsed\logkit.jar;%CLASSPATH%" org.jacorb.idl.parser ../../../../../../idl/DurabilityData.idl
java -classpath "%JACORB_HOME%\lib\idl.jar;%JACORB_HOME%\lib\endorsed\logkit.jar;%CLASSPATH%" org.jacorb.idl.parser ../../../../../../idl/DurabilityData.idl
IF NOT ERRORLEVEL==0 (
  ECHO:
  ECHO *** Generation of jacorb java class from IDL failed
  ECHO:
  GOTO error
)

REM
REM Compile generated java code
REM
echo "Compile generated Java classes"
echo === javac -classpath ".;%OSPL_HOME%/jar/dcpssaj.jar" -d ../classes ./DurabilityData/*.java
javac -classpath ".;%OSPL_HOME%/jar/dcpssaj.jar" -d ../classes ./DurabilityData/*.java
IF NOT ERRORLEVEL==0 (
  ECHO:
  ECHO *** Compilation of generated Java classes failed
  ECHO:
  GOTO error
)

REM
REM Compile application java code
REM
echo "Compile application Java classes"
cd ..
cd
javac -classpath .;idlpp;"%OSPL_HOME%/jar/dcpssaj.jar" -d ./classes ../../../../src/*.java
IF NOT ERRORLEVEL==0 (
  ECHO:
  ECHO *** Compilation of application Java classes failed
  ECHO:
  GOTO error
)
REM
REM Create jar files
REM
echo "Create jar files"
cd ../exec
cd
jar cf DurabilityDataSubscriber.jar -C ../bld/classes . 
jar cf DurabilityDataPublisher.jar -C ../bld/classes .

cd ..
GOTO end

:error
ECHO An error occurred, exiting now
:end


clc
clear
warning('off'); 



//********************************************************************
//********************************************************************
// Main program
// Convert FIR-correction filters from Acourate to miniSharc 96kHz
// Call parameters:
//   .../Calculate_miniSharc_Filters.sce" -args INIT
//   .../Calculate_miniSharc_Filters.sce" -args WH
//   .../Calculate_miniSharc_Filters.sce" -args MAIN
//   .../Calculate_miniSharc_Filters.sce" [-args SINGLE]
//
//!! Die Lib sollte in zwei Teile gesplittet werden, eine für Basic function sund 
//!! eine die ich nur führ dieses Programm brauche
//
//********************************************************************
//********************************************************************

    // Get arguments and test if arguments valid
    args = sciargs();

    if  size(args,1)<>5 then
        if size(args,1)==3 then
            args(5) = "SINGLE";
        else
            disp ('USAGE: <path to scilab>\scilex.exe -f <path to script>\Calculate_miniSharc_Filters.sce [-args INIT|WH|MAIN]');
            anyKey = input ("Press return to terminate: ");
            exit(1);
        end
        
    end
    
    // Get parameter, may be reltive or absolute Path to SCILAB script
    appPath = args(3); 
    absoluteAppPath = appPath;
    operationMode = args(5);

    // Get current path (path to acourate result files)
    currentPath = pwd();
    appPath = dirname(appPath);

    // change to path of application
    chdir (appPath);
    absoluteAppPath = pwd();
    absoluteAppPath = absoluteAppPath + '\';
    
    // go back to current path
    chdir(currentPath);

    // Path for Library
    myLibPath = absoluteAppPath + 'scLib\';

    // Library load
    disp (myLibPath);
    myLib = lib (myLibPath);
    
    // Get global functions
    globalFunctions();
    global readImpulseFile;
    global readImpulseFileSingleInt;
    global writeImpulseFile;
    global writeImpulseFileSingle;
    global rotateLeft;
    global rotateRight;
    global calcAmplitude;
    global extendFFT;
    global minImpulsFromAmplitude;
    global phaseExtract;
    global minImpulsFromSos;
    global calculateFilter;
    global calculateSubtractiveDelayedHp;
    global convertToSinglePrecisionHex;
    global calculateResapledFiles;


    //********************************************************************
    // Diverse definitions
    //********************************************************************

    // Name of input configuration files for miniSharc
    MiniSharcXoFile = absoluteAppPath + "!MiniSharc-Default.xml";
    MiniSharcSingleSpeakerFile = absoluteAppPath + "!MiniSharc-Default.xml";
    
    // Name of the output configuration file for miniSharc
    MiniSharcConfigFile = "!MiniSharc-Config.xml";

    // Definition if correction files for Audiovolver should be genaerated
    generateForAV = %f;  // keep at %f not well tested...

    // Set process parameters
    fs = 96000;          // Taget samplerate of miniSharc
    fsIn = 44100;        // Samplerate of input correction filter
    xoOrder = 6;         // Order of XO Bessel filter (6 is fine)
    xoFrequency = 130    // Crossover frequency of XO Bessel filter (-6db)
    fPoints = 8192*2;    // Number of frequency points for SOS Aproximation
    pulseLength = 65536; // Length of generated test convolution

    // miniSharc channel definitition of Input-PEQ-Filter in 
    I2SleftIn    = 1;  // I2S In 1
    I2SrightIn   = 2;  // I2S In 2
    SPDIFleftIn  = 3;  // SPDIF In 1
    SPDIFrightIn = 4;  // SPDIF In 2

    // miniSharc channel definition for speaker without XO
    SpeakerLeftOut    = 5; // Out 1
    SpeakerRightOut   = 6; // Out 2
    
    // miniSharc channel definition of Output-Woofer-PEQ-Filter with XO
    WooferLeftOut    = 5; // Out 1
    WooferRightOut   = 6; // Out 2

    // miniSharc channel definitition of Output-Horn-Filter with XO
    HornLeftOut    = 11; // Out 7
    HornRightOut   = 12; // Out 8




    //********************************************************************
    //********************************************************************
    // Operation Mode SINGLE = Correction without active 2-way system
    // Use this mode after processing the measurement with Acourate
    // and run this script to get the SOSs and config file for miniSharc
    //********************************************************************
    //********************************************************************
    if  operationMode == "SINGLE" then
        printf ('\nOperation mode is: Single channel Correction\n');
        
        // Initial copy the miniSharc configuration file
        copyfile(MiniSharcSingleSpeakerFile, MiniSharcConfigFile);

        // Calculate 54 coefficients = 27 Bi-Quads. 
        // 9 Bi-Quads for input PEQs
        // 10 Bi-Quads for output PEQs
        // 8 Bi-Quads for XO section
        orderLow  = 46; orderHigh = 8; // best fit for passive speakers, can be changed BUT sum must be 36!!

        pulseIn = "Pulse44L.dbl";
        printf ('\nCalculate filter for Speaker\\'+pulseIn+'\n');
        channel = 3;
        direction = "L";
        //orderLow  = 28; orderHigh = 8; // best fit for passive speakers, can be changed BUT sum must be 36!!
        [sos2L, gain2L, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 44100, fPoints, orderLow, orderHigh, pulseLength);
        if generateForAV then
            [sos2L, gain2L, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 48000, fPoints, orderLow, orderHigh, pulseLength);
            [sos2L, gain2L, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 88200, fPoints, orderLow, orderHigh, pulseLength);
        end
        [sos2L, gain2L, firHex2L]    = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 96000, fPoints, orderLow, orderHigh, pulseLength);

        // Split sos to one part for input PEQ and output PEQ+XO
        sos2LOut = sos2L(1:$,1:18);
        sub2LIn = sos2L(1:$,19:$);

        pulseIn = "Pulse44R.dbl";
        printf ('\nCalculate filter for Speaker\\'+pulseIn+'\n');
        channel = 3;
        direction = "R";
        //orderLow  = 28; orderHigh = 8; // best fit for passive speakers, can be changed BUT sum must be 36!!
        [sos2R, gain2R, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 44100, fPoints, orderLow, orderHigh, pulseLength);
         if generateForAV then
            [sos2R, gain2R, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 48000, fPoints, orderLow, orderHigh, pulseLength);
            [sos2R, gain2R, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 88200, fPoints, orderLow, orderHigh, pulseLength);
        end
        [sos2R, gain2R, firHex2R]    = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 96000, fPoints, orderLow, orderHigh, pulseLength);

        // Split sos to one part for input PEQ and output PEQ+XO
        sos2ROut = sos2R(1:$,1:18);
        sub2RIn = sos2R(1:$,19:$);


        // Write input filters to PEQs
        retval = writeXmlSharc (sub2LIn, gain2L, MiniSharcConfigFile, "PEQ", I2SleftIn);
        retval = writeXmlSharc (sub2LIn, gain2L, MiniSharcConfigFile, "PEQ", SPDIFleftIn);
        retval = writeXmlSharc (sub2RIn, gain2R, MiniSharcConfigFile, "PEQ", I2SrightIn);
        retval = writeXmlSharc (sub2RIn, gain2R, MiniSharcConfigFile, "PEQ", SPDIFrightIn);


        // Write SOS coefficients to PEQ und Xover
        // Speaker left: PEQ_5_1 to PEQ_5_10
        retval = writeXmlSharc (sos2LOut, gain2L, MiniSharcConfigFile, "PEQ", SpeakerLeftOut);

        // Speaker Left: BBPF_5_1 to BPF_5_5
        retval = writeXmlSharc (sos2LOut, gain2L, MiniSharcConfigFile, "BPF", SpeakerLeftOut);
              
        // Speaker Right: PEQ_6_1 to PEQ_6_10
        retval = writeXmlSharc (sos2ROut, gain2R, MiniSharcConfigFile, "PEQ", SpeakerRightOut);
        
        // Speaker Right: BPF_6_1 to BPF_6_5
        retval = writeXmlSharc (sos2ROut, gain2R, MiniSharcConfigFile, "BPF", SpeakerRightOut);
        
        // Write firHex1L and firHex1R to FIR-part of config file
        retval = writeXmlSharcFir (firHex2L, MiniSharcConfigFile, SpeakerLeftOut);
        retval = writeXmlSharcFir (firHex2R, MiniSharcConfigFile, SpeakerRightOut);


        //********************************************************************
        // Create Filter for Audiovolver before MAIN measurement in
        // folder AudiovolverBeforeMain
        //********************************************************************
        if generateForAV then
            printf ('\nCalculate Audiovolver Filter for MAIN measurement to AudiovolverBeforeMain\n');
            createAVforMainMeasurement (pulseLength, delayForHornLeft, delayForHornRight);
        end
    end





    //********************************************************************
    //********************************************************************
    // Operation Mode WH = Woofer & Horn
    // First measure horn and woofer separately.
    // Run the script in "WH"" mode
    // Then adjust the delay and volume by measuring Horn and Woofer together
    // Next run the Script in "MAIN" mode
    //********************************************************************
    //********************************************************************
    if  operationMode == "WH" then

        printf ('\nOperation mode is: Woofer&Horn\n');
        
        delayForHornLeft = 0;
        delayForHornRight = 0;
        
        if generateForAV then
            // get delay for Horn
            delayForHornLeft = input ("Enter delay in Samples for Horn left: ");
            if delayForHornLeft == [] then
                delayForHornLeft = 0;
            end
            
            // get delay for right Woofer
            delayForHornRight = input ("Enter delay in Samples for Horn right: ");
            if delayForHornRight == [] then
                delayForHornRight = 0;
            end
        end


        //********************************************************************
        // Calculation for Woofer
        //********************************************************************
        res = chdir ('.\Woofer');
        if res == %f then
            disp ('ERROR: Subdirectory Woofer not found');
            pause();
            exit(1);
        end
    
        pulseIn = "Pulse44L.dbl";
        printf ('\nCalculate filter for Woofer\\'+pulseIn+'\n');
        channel = 1;
        direction = "L";
        orderLow  = 20; orderHigh = 16; // best fit for my system, can be changed BUT sum must be 36!
        [sos1L, gain1L, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, fs, fPoints, orderLow, orderHigh, pulseLength);

        pulseIn = "Pulse44R.dbl";
        printf ('\nCalculate filter for Woofer\\'+pulseIn+'\n');
        channel = 1;
        direction = "R";
        orderLow  = 20; orderHigh = 16; // best fit for my system, can be changed BUT sum must be 36!
        [sos1R, gain1R firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, fs, fPoints, orderLow, orderHigh, pulseLength);

        // back to home directory
        res = chdir ('..\');


        // Write SOS coefficients to PEQ und Xover
        // Woofer left: PEQ_5_1 to PEQ_5_10
        retval = writeXmlSharc (sos1L, gain1L, MiniSharcConfigFile, "PEQ", WooferLeftOut);
        // Woofer Left: BPF_5_1 to BPF_5_5
        retval = writeXmlSharc (sos1L, gain1L, MiniSharcConfigFile, "BPF", WooferLeftOut);
        // Woofer left: PEQ_6_1 to PEQ_6_10
        retval = writeXmlSharc (sos1R, gain1R, MiniSharcConfigFile, "PEQ", WooferRightOut);
        // Woofer Right: BPF_6_1 to BPF_6_5
        retval = writeXmlSharc (sos1R, gain1R, MiniSharcConfigFile, "BPF", WooferRightOut);

    
    
        //********************************************************************
        // Calculation for Horn
        //********************************************************************
        res = chdir ('.\Horn');
        if res == %f then
            disp ('ERROR: Subdirectory Horn not found');
            pause();
            exit(1);
        end
    
        pulseIn = "Pulse44L.dbl";
        printf ('\nCalculate filter for Horn\\'+pulseIn+'\n');
        channel = 2;
        direction = "L";
        orderLow  = 28; orderHigh = 8; // best fit for my system, can be changed BUT sum must be 36!
        [sos2L, gain2L, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 44100, fPoints, orderLow, orderHigh, pulseLength);
        if generateForAV then
            [sos2L, gain2L, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 48000, fPoints, orderLow, orderHigh, pulseLength);
            [sos2L, gain2L, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 88200, fPoints, orderLow, orderHigh, pulseLength);
        end
    
        [sos2L, gain2L, firHex2L]    = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 96000, fPoints, orderLow, orderHigh, pulseLength);

        pulseIn = "Pulse44R.dbl";
        printf ('\nCalculate filter for Horn\\'+pulseIn+'\n');
        channel = 2;
        direction = "R";
        orderLow  = 28; orderHigh = 8; // best fit for my system, can be changed BUT sum must be 36!
        [sos2R, gain2R, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 44100, fPoints, orderLow, orderHigh, pulseLength);
         if generateForAV then
            [sos2R, gain2R, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 48000, fPoints, orderLow, orderHigh, pulseLength);
            [sos2R, gain2R, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 88200, fPoints, orderLow, orderHigh, pulseLength);
        end
        [sos2R, gain2R, firHex2R]    = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, 96000, fPoints, orderLow, orderHigh, pulseLength);

        // back to home directory
        res = chdir ('..\');

       
        // Write SOS coefficients to PEQ und Xover
        // Horn left: PEQ_11_1 to PEQ_11_10
        retval = writeXmlSharc (sos2L, gain2L, MiniSharcConfigFile, "PEQ", HornLeftOut);

        // Horn Left: BPF_11_1 to BPF_11_5
        retval = writeXmlSharc (sos2L, gain2L, MiniSharcConfigFile, "BPF", HornLeftOut);
              
        // Horn Right: PEQ_12_1 to PEQ_12_10
        retval = writeXmlSharc (sos2R, gain2R, MiniSharcConfigFile, "PEQ", HornRightOut);
        
        // Horn Right: BPF_12_1 to BPF_12_5
        retval = writeXmlSharc (sos2R, gain2R, MiniSharcConfigFile, "BPF", HornRightOut);

        // Write firHex1L and firHex1R to FIR-part of config file
        retval = writeXmlSharcFir (firHex2L, MiniSharcConfigFile, HornLeftOut);
        retval = writeXmlSharcFir (firHex2R, MiniSharcConfigFile, HornRightOut);


        //********************************************************************
        // Create Filter for Audiovolver before MAIN measurement in
        // folder AudiovolverBeforeMain
        //********************************************************************
        if generateForAV then
            printf ('\nCalculate Audiovolver Filter for MAIN measurement to AudiovolverBeforeMain\n');
            createAVforMainMeasurement (pulseLength, delayForHornLeft, delayForHornRight);
        end
    end





    //********************************************************************
    //********************************************************************
    // Operation Mode MAIN = Main Correction und Target
    // After adjusting amplitude and delay between Woofer and Horn take
    // a new measurement with both active and calculate correction.
    // Then run this script to get the SOSs for the main path
    //********************************************************************
    //********************************************************************
    if  operationMode == "MAIN" then
        printf ('\nOperation mode is: Main Correction\n');

        pulseIn = "Pulse44L.dbl";
        printf ('\nCalculate filter for Main Control\\'+pulseIn+'\n');
        channel = 1;
        direction = "L";
        orderLow  = 12; orderHigh = 6; // best fit for active system final overall correction, can be changed BUT sum must be 18!!
        [sos1L, gain1L, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, fs, fPoints, orderLow, orderHigh, pulseLength);
        
        pulseIn = "Pulse44R.dbl";
        printf ('\nCalculate filter for Main Control\\'+pulseIn+'\n');
        channel = 1;
        direction = "R";
        orderLow  = 12; orderHigh = 6; // best fit for active system final overall correction, can be changed BUT sum must be 18!!
        [sos1R, gain1R, firHexDummy] = processChannel (pulseIn, channel, xoOrder, xoFrequency, direction, fsIn, fs, fPoints, orderLow, orderHigh, pulseLength);

      
        // Write SOSs to input miniSharc filters for I2S and SPDIF
        retval = writeXmlSharc (sos1L, gain1L, MiniSharcConfigFile, "PEQ", I2SleftIn);
        retval = writeXmlSharc (sos1L, gain1L, MiniSharcConfigFile, "PEQ", SPDIFleftIn);
        retval = writeXmlSharc (sos1R, gain1L, MiniSharcConfigFile, "PEQ", I2SrightIn);
        retval = writeXmlSharc (sos1R, gain1L, MiniSharcConfigFile, "PEQ", SPDIFrightIn);


        //********************************************************************
        // Create Filter for Audiovolver Final 
        // folder AudiovolverFinal
        //********************************************************************
        if generateForAV then
            printf ('\nCalculate final Audiovolver Filter to AudiovolverFinal\n');
            createAVfinal (pulseLength);
        end

    end





    //********************************************************************
    //********************************************************************
    // Operation Mode INIT has to bestartet at the beginning.
    // it sets up the Target curves for the Horn and the Woofer
    //********************************************************************
    //********************************************************************
    if  operationMode == "INIT" then
        printf ('\nOperation mode is: Initialization\n');
        
        sampleRate = 44100;
        
        // Calculate Lowpass filter for the crossover
        [filterLp, epOffset] = calculateFilter ("BesselLP", sampleRate, xoFrequency, xoOrder, pulseLength);
        writeImpulseFile (".\Woofer\Target.dbl", filterLp);

        // Calculate the phase correction for the Horn
        delayedHp = calculateSubtractiveDelayedHp (filterLp, epOffset);
        writeImpulseFile (".\Horn\Target.dbl", delayedHp);
        
        // Initial copy the miniSharc configuration file
        copyfile(MiniSharcXoFile, MiniSharcConfigFile);
    end


    disp("");
    anyKey = input ("FINISHED: Press return to terminate: ");
    exit();











    


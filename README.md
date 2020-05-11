Use Acourate FIR filters with miniSharc from miniDSP-Ltd.
=========================================================

The software [Acourate®](https://www.audiovero.de/en/) produces Word-Class room
correction FIR-filters for audio systems. To use these FIR-filters special
hardware (like the
[Audiovolver®](https://www.audiodata.eu/products/audiovolver.html)) or a
software convolution engine like [roon®](https://roonlabs.com/) must be used.

This SCILAB script is an approach to convert the Acourate FIR-filters into an
XML-configuration file for the **miniSharc** platform from miniDsp Ltd. To load
the XML-configuration file into the miniSharc you must use the miniSHARC-4x8-96k plugin from miniDsp Ltd.

The calculated XML-configuration file !MiniSharc-Config.xml uses the FIR-section
of the miniShrac and all IIR filters available. So, the PEQ filters at the
inputs, and the PEQ and Xover sections are filled with the calculated Bi-Quads.
Therefore, the filter curves in the display of the miniSharc plugin sometimes
look quite strange but the overall output is correct.

To run the script SCILAB 6.0.2 must be installed on your Windows-10 PC that can
be downloaded [here](https://www.scilab.org/download/6.0.2).

In the example folder files reside, that are produces by Acourate when a
measurement was taken with 44.1kHz and correction filters for 44.1 and 96kHz
were generated. You must have these files in your Acourate working directory to
run the script.

The script is run by starting !Run_Excample.cmd. It creates the
!MiniSharc-Config.xml in the example folder (and also some others) and in the
subdirectory TestConvolution the files Test44L.dbl and Test44L.dbl. These files
show what you will get with the miniSharc in comparison to the Pulse44L.dbl and
Pulse44R.dbl that the FIR filters will provide.

You will find that the difference (except a small gain difference) will be
neglectable small, even if you compare the step response. The FIR-part in the
miniSharc nicely corrects phase errors in the frequency region above 300Hz so
time delays of the tweeter crossover are well compensated.

The example and the provided documentation in the doc folder are for a passive
passive speaker setup only. With the script also can provide corrections for
active two-way systems with even better phase correction the lower frequency
range. For information regarding this please send a personal mail.

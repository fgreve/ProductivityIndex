# ProductivityIndex

## Total Factor Productivity Metrics for Chile

The code in this folder automatically generates TFP measurement under the CNP methodology reported in the (1st) Annual Productivity Report 2016.

Files in this folder:
1. PTF_IPROD_2016: calculation code.
2. INE and BC: Inputs for the calculation.
3. DATA: This template copies the series generated by the code.

* In addition to the above mentioned files, reference should be made to a folder where CASEN Surveys are kept (until 2015).

Functioning:
It consists of running the code (`PTF_IPROD_2016.do`). This code takes the inputs:INE, BC and CASEN and finally copies the series in the "data" sheet of the `DATA` sheet.

For proper operation, the necessary packages must be installed (specified at the beginning of the code), along with specifying the Paths or folders where the PTF folder is located and where the CASEN Surveys are located.

Once the code is executed several .dta files are generated, which serve as byproducts in the process.
To re-execute the code it is not necessary to delete these files as they are replaced.

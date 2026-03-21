# ECN 726 Term Project: Replication Package
**Paper:** Fajgelbaum, P. D., et al. (2024). "The US-China Trade War and Global Reallocations."

## Project Overview
The main text of the paper contains four primary figures (pages 16-20) designated for replication. 
* **Successfully Replicated:** Figure 1 and Figure 4. 
* **Incomplete Replication:** Figure 2 and Figure 3. As noted in the authors' original documentation, generating these specific figures requires specialized enterprise computing resources, preventing local replication.

## Instructions for Execution (Copy/Paste Workflow)
To reproduce the available figures, please follow this exact sequence in Stata. To bypass the 256GB RAM memory requirement needed to build the massive raw UN Comtrade files, this execution relies entirely on the pre-processed baseline datasets (`data5.dta` and `rf.dta`) located in the `/data/processed/` folder.

**Step 1: Path Setup & Figure 1**
First, open `code/00_directories.do` and update the `global db` path to match your local machine. Then, copy and paste this into the Stata Command window:

```stata
cd "/path/to/your/folder/The US-China Trade War and Global Reallocations  GTW_replication/code"
do 00_directories.do
do didplots.do
```

*Result:* `fig_1.pdf` will be successfully generated in the `/results/` folder. *(Note: `didplots.do` changes the working directory to `/tmp/` at the very end).*

**Step 2: Baseline Regressions & The Hardware Error**
Because the previous script changed the active directory, you must point Stata back to the code folder before running `winners.do`. Copy and paste:

```stata
cd "/path/to/your/folder/The US-China Trade War and Global Reallocations  GTW_replication/code"
do winners.do
```

*Result:* **This script will intentionally crash with a red error** (`file ... bs1.dta not found`). This is expected. The script successfully calculates the baseline regressions, but halts when it attempts to merge 50 massive bootstrap datasets to draw the maps for Figures 2 and 3. As the authors note, compiling these bootstraps requires a Linux server with 64 cores and 256GB of RAM, meaning they cannot be generated on a local machine.

**Step 3: Figure 4**
Even though the previous script halted, it successfully generated the necessary baseline data before crashing. You do not need to change directories again. Simply copy and paste the final script:

```stata
do quadplot.do
```

*Result:* `fig_4.pdf` will be successfully generated in the `/results/` folder.

## Detailed Explanation for Incomplete Replication
Per the ECN 726 project guidelines, this section explains why Figures 2 and 3 could not be replicated locally.

The authors' code constructs the maps for Figures 2 and 3 by calculating confidence intervals through a 50-iteration bootstrap loop (requiring the merging of `bs1.dta` through `bs50.dta`). 

**The Hardware Limitation:** The authors explicitly state that executing these bootstraps requires a high-performance Linux server equipped with **64 cores and 256 GB of RAM**. 

Because a standard local computer cannot support this extreme memory threshold, the bootstrap datasets cannot be generated. Consequently, the `winners.do` script halts execution during the merge loop, preventing the creation of the final map PDFs. 

**Impact on Main Results:** It is important to note that this hardware limitation only prevents the calculation of the bootstrapped confidence intervals and map extensions. It does not affect the baseline point estimates, which have been successfully executed, verified, and mapped in Figures 1 and 4.
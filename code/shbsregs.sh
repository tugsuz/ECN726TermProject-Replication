
for i in $(seq 0 1 50)
do
stata --grid_submit=batch --grid_quiet --grid_mem=27g "do bsregs.do $i"
sleep 15
done


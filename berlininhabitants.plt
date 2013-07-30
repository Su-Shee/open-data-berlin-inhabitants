reset
unset key

set terminal pngcairo size 700,900 enhanced font "Verdana, 10"
set output "berlin-inhabitants.png"

unset title

set style data histogram
set style histogram gap 1

set style line 1 lt 1 lc rgb "#ab003c"
set style line 2 lt 1 lc rgb "#006b55"

set grid linestyle 2
set style fill solid
set boxwidth 0.8

set yrange [100000:250000]
set autoscale x

set xtics rotate by 90 scale 0 font "Verdana, 10"
set xtics offset 0, graph -0.2

unset ytics
set y2tics out rotate by 90 font "Verdana, 8"

set y2label 'number of women' offset -2.5 centre font "Verdana, 10"
set ylabel "Berlin's districts by number of women" offset -2.5 centre font "Verdana, 14"

set x2label 'district' centre rotate by 180 font "Verdana, 10"

plot 'top10women.dat' using 0:xtic(1), \
     'top10women.dat' using 2 with boxes linestyle 2

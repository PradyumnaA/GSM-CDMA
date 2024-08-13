# Define GSM network parameters
set bwDL(gsm) 9600
set bwUL(gsm) 9600
set propDL(gsm) 0.500
set propUL(gsm) 0.500
set buf(gsm) 10

# Create a new simulator instance and open a trace file
set ns [new Simulator]
set trace_file [open Lab5.tr w]
$ns trace-all $trace_file

# Initialize nodes for the cellular network
set nodes(c1) [$ns node]
set nodes(ms) [$ns node]
set nodes(bs1) [$ns node]
set nodes(bs2) [$ns node]
set nodes(c2) [$ns node]

# Procedure to set up the cellular network topology
proc cell_topo {} {
    global ns nodes
    $ns duplex-link $nodes(c1) $nodes(bs1) 3Mbps 10ms DropTail
    $ns duplex-link $nodes(bs1) $nodes(ms) 1 1 RED
    $ns duplex-link $nodes(ms) $nodes(bs2) 1 1 RED
    $ns duplex-link $nodes(bs2) $nodes(c2) 3Mbps 50ms DropTail
}

# Switch-case for setting up different network types (GSM, GPRS, UMTS)
switch gsm {
    gsm -
    gprs -
    umts {cell_topo}
}

# Set up link parameters for GSM network
$ns bandwidth $nodes(bs1) $nodes(ms) $bwDL(gsm) simplex
$ns bandwidth $nodes(ms) $nodes(bs1) $bwUL(gsm) simplex
$ns bandwidth $nodes(bs2) $nodes(ms) $bwDL(gsm) simplex
$ns bandwidth $nodes(ms) $nodes(bs2) $bwUL(gsm) simplex
$ns delay $nodes(bs1) $nodes(ms) $propDL(gsm) simplex
$ns delay $nodes(ms) $nodes(bs1) $propUL(gsm) simplex
$ns delay $nodes(bs2) $nodes(ms) $propDL(gsm) simplex
$ns delay $nodes(ms) $nodes(bs2) $propUL(gsm) simplex
$ns queue-limit $nodes(bs1) $nodes(ms) $buf(gsm)
$ns queue-limit $nodes(ms) $nodes(bs1) $buf(gsm)
$ns queue-limit $nodes(bs2) $nodes(ms) $buf(gsm)
$ns queue-limit $nodes(ms) $nodes(bs2) $buf(gsm)

# Insert delayers on links
$ns insert-delayer $nodes(ms) $nodes(bs1) [new Delayer]
$ns insert-delayer $nodes(bs1) $nodes(ms) [new Delayer]
$ns insert-delayer $nodes(ms) $nodes(bs2) [new Delayer]
$ns insert-delayer $nodes(bs2) $nodes(ms) [new Delayer]

# Set up TCP communication between c1 and c2
set tcp [new Agent/TCP]
$ns attach-agent $nodes(c1) $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $nodes(c2) $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns connect $tcp $sink

# Define procedure to end simulation
proc End {} {
    global ns trace_file
    $ns flush-trace
    close $trace_file
    exec awk -f Lab5.awk Lab5.tr &
    exec xgraph -P -bar -x TIME -y DATA gsm.xg &
    exit 0
}

# Schedule events: Start FTP at time 0.0, end simulation at time 10.0
$ns at 0.0 "$ftp start"
$ns at 10.0 "End"

# Run the simulation
$ns run
BEGIN {Total_no_of_pkts=0;}

{
    if($1 == "r") {
        Total_no_of_pkts = Total_no_of_pkts + $6;
        printf("%f %d\n", $2, Total_no_of_pkts) >> "gsm.xg"
    }
}

END{}

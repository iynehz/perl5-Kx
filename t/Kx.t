# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Kx.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 71;
#use Test::More qw(no_plan);
use Data::Dumper;
BEGIN { use_ok('Kx') };


my $fail = 0;
foreach my $constname (qw(
	KC KD KE KF KG KH KI KJ KM KS KT KU KV KZ XD XT)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Kx macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#my $k = new Kx(host=>"localhost", port=>2080);
#my $k = new Kx(host=>"localhost", port=>2222, 'userpass' => 'markpf:letmein', check_for_errors=>1);
my $k = new Kx(host=>"localhost", port=>2222, check_for_errors=>1);
ok( defined $k, 'New');

my $rv = $k->connect;
ok(defined $rv, 'Connect');
die "Can't connect to KDB+ " unless $rv;

# Big bang test straight up, Stuff a hash of interetsing stuff into Kdb+
# and get it back for comparision, restuff it then compare it in Kdb+
# and get the result back. Then test to see its OK
%p = (
	'192.168.1.200' => ['Changes', 'K-0.01.tar.gz', 'K.bs'],
	'K.c' => [ {'K.o' => 'K.xs'},  {'MANIFEST' => 'META.yml'}, 'Makefile'],
	'Makefile.PL' => 'README',
	'a.out' => 'accessors-c.inc',
	'accessors-xs.inc' => 'blib',
	'c.c' => 'c.o',
	'const-c.inc' => 'const-xs.inc',
	'fallback' => 'filename',
	'k.h' => 'kc.o',
	'ktrace.out' => 'lib',
	'libkdb.a' => 'pm_to_blib',
	'ppport.h' => 't',
	'test.c' => {'20' => 'twenty', '30' => [1,2,3,4,5]},
);
$kz = $k->perl2k(\%p);
$k->cmd('{a::x}',$kz->kval);
$p = $k->cmd('a');
$kz = $k->perl2k($p);
$k->cmd('{b::x}',$kz->kval);

$r = $k->cmd('asc a = asc b');
is($r->{'192.168.1.200'}[0], 1, "192.168.1.200[0]");
is($r->{'192.168.1.200'}[1], 1, "192.168.1.200[1]");
is($r->{'192.168.1.200'}[2], 1, "192.168.1.200[2]");
is($r->{'test.c'}{'30'}[0], 1, "test.c{30}[0]");
is($r->{'test.c'}{'30'}[1], 1, "test.c{30}[1]");
is($r->{'test.c'}{'30'}[2], 1, "test.c{30}[2]");
is($r->{'test.c'}{'30'}[3], 1, "test.c{30}[3]");
is($r->{'test.c'}{'30'}[4], 1, "test.c{30}[4]");
is($r->{'accessors-xs.inc'},1, "accessors-xs.inc");
is($r->{'K.c'}[0]{'K.o'},1, "K.c[0]{K.o}");
is($r->{'K.c'}[1]{'MANIFEST'},1, "K.c[1]{MANIFEST}");
is($r->{'K.c'}[2],1, "K.c[2]");

#q)aa 
#st1      | ,0j        0 1j       0 1 2j     0 1 2 3j   0 1 2 3 4j 0 1 2 3 4 5..
#interface| interface0 interface1 interface2 interface3 interface4 interface5 ..
#st2      | ,0j        0 1j       0 1 2j     0 1 2 3j   0 1 2 3 4j 0 1 2 3 4 5..
$x = {
	"interface" => [ map {"interface$_"} 0..20],
	"st1"       => [ map {[0..$_]} 0..20],
	"st2"       => [ map {[0..$_]} 0..20],
};
$kz = $k->perl2k($x);
$k->cmd('{aa::x}',$kz->kval);
$a = $k->cmd('aa');
is($a->{st1}[4][4], $x->{st1}[4][4], "Dict of arrays");

# Try a keyed table, selected many times
$k->cmd('l: ([a:1 2 3] b:4 5 6)');
$a = $k->cmd('l') for(0..100);
$b = $k->cmd('select from l') for(0..100);
is($a->{a}[2], $b->{a}[2], "keyed table elements the same");

# 
# Create Atoms
#
my $d = $k->bool(0);           # boolean
is($d->val,0, "Boolean");

$d = $k->byte(100);         # char
is($d->val, 100, "Byte");

$d = $k->char(ord('a'));    # char
is($d->val, ord('a'), "Char");

$d = $k->short(20);
is($d->val, 20, "Short");

$d = $k->int(70);
is($d->val, 70, "Int");

$d = $k->long(93939);
is($d->val, 93939, "Long");

$d = $k->real(20.44);
like($d->val, qr/^20\.44/, "Real");

$d = $k->float(20.44);
like($d->val, qr/^20\.44/, "Float");

$d = $k->sym('mysymbol');    # A Kdb+ symbol
is($d->val, 'mysymbol', "Symbol");

$d = $k->date(2007,4,22);    # integer encoded date year, month, day
my @time = localtime($d->val);
$time[5]+=1900;
$time[4]++;
is($time[5].$time[4].$time[3],"2007422", "Date");

$now = time;
$d = $k->dt($now);         # Kdb+ datetime from epoch
is($d->val, $now, "DateTime");

$d = $k->tm(100);            # Time type in milliseconds
is($d->val, 100, "Milliseconds");

# Simple lists
# Kx::ktn(type, length)
my $size=20;
my $iter=1000;
my $l = $k->listof($size,Kx::KS());
for(my $y=0; $y < $iter; $y++)
{
	for( my $i=0; $i < $size; $i++)
	{
		$l->at($i,"symbol$i");
	}
}
for( my $i=0; $i < $size; $i++)
{
	$l->at($i,"symbol$i");
	is($l->at($i), "symbol$i", "Simple List $i");
}

# Add an extra symbol
my $sym = $k->sym("hi there");
$l->joinatom($sym);
my $perl_list = $l->list();
is($l->at($size), 'hi there', "Add symbol to list");

# Check out the dates now
$l = $k->listof($size,Kx::KD());
for( my $i=0; $i < $size; $i++)
{
	$l->at($i,2007,4,$i+1);  # 20070401 -> 20070420
}
@time = localtime($l->at(19));
$time[5]+=1900;
$time[4]++;
is($time[5].$time[4].$time[3],"2007420", "Date list");

# Add an extra date to the end of the list
$l->joinatom($k->date(2007,4,30));
$perl_list = $l->list();
@time = localtime($l->at($size));
$time[5]+=1900;
$time[4]++;
is($time[5].$time[4].$time[3],"2007430", "Add Date to list");

# Create a mixed list and check it
$l = $k->listof(3,0);  # 3 elemenst long type is 0
$l->at(0,$k->float(5.0));
$l->at(1,$k->sym('five'));
$l->at(2,$k->bool(1));
is($l->at(0), 5, "Mixed list 0 is 5.0" );
is($l->at(1), 'five', 'Mixed list 1 is "five"');
is($l->at(2), 1, 'Mixed list 2 is 1');

# Create a Kdb+ symbol list from an array reference
my $arr = [qw/one two three four five six/];
$k->av2k(Kx::KS(),$arr);
is($k->at(4),'five', "Symbol list from Array ref");
$perl_list = $k->list();

# Get the server's environmental details
$k->env;
my $ref = $k->tables;
print "Tables are: @$ref\n";
$ref = $k->funcs;
print "Functions defined are: @$ref\n";
$ref = $k->views;
print "Views defined are: @$ref\n";
$ref = $k->variables;
print "Variables defined are: @$ref\n";
$ref = $k->GMToffset;
print "GMToffset is $ref\n";

my $time = time;
$k->Tnew(name=>"t",cols=>[qw/tm k v/]);
my $now = time;
my $c = 50;
my $z = ".z.z;" x $c;
chop($z);
for my $i (0..(int(1000/$c)))
{
	my @v = map {$_ * $i} (1..$c);
	my $key=join(" ", ($i) x $c);
	$k->whenever("insert[`t](tm:($z);k:($key);v:(@v))");
}
print "Took ",time-$now,"s\n";
ok($k->Tselect('a',"select from t where k=2"), 'Select a');

my $numrows = $k->Tnumrows('a');
ok($numrows == 50,'Numrows');

my $numcols = $k->Tnumcols('a');
ok($numcols == 3, 'Numcols');

ok($k->Tget('a'), 'Tget a');
is($k->Tindex(3,2), 8, 'Tindex a');
is($k->Theader()->[1], 'k', 'Theader a');
is($k->Tcol(1)->[20],2, 'Tcol a');
$type = ($k->Tmeta('a'))[0]->[1];
$type = 'z' if  $type eq 'datetime';
is($type, 'z', 'Tmeta a');

# Check cmd()
$x = $k->cmd('count a');
is($x,50,'cmd() Scalar');

$x = $k->cmd('b: "abcd"');
$x = $k->cmd('b');
is($x,'abcd','cmd() char list');

$s = 'xyzzy';
$val = $k->listof(length($s),Kx::KG());
$val->setbin($s);
$x = $k->cmd('{b:: x}',$val->kval);
$x = $k->cmd('b');
is($x,$s,'cmd() char, listof, setbin, k1');

$s  = 'xyzzy';
$s1 = 'xyzzy';
$val = $k->listof(length($s),Kx::KG());
$val->setbin($s);
$val2 = $k->listof(length($s),Kx::KG());
$val2->setbin($s);
$x = $k->cmd('{b:: x,y}',$val->kval,$val2->kval);
$x = $k->cmd('b');
is($x,$s.$s1,'cmd() char, listof, setbin, k2');

$rtn = $k->cmd('a');
is($rtn->{'v'}[49],100,'cmd() table into hash');
$k->Tget('a');
is($k->Tindex(3,2), 8, 'cmd() then Tindex a');

# Kx::kp(symbol)
# Kx::kpn(string, length)
# 
# Extend Lists
# Kx::ja(klist, atom)
# Kx::js(klist, string)
# Kx::jk(klist, kobject)
#
# Dicts and Tables
# Kx::xT(dict)
# Kx::xD(keys, values)


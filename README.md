# NAME

Kx - Perl extension for Kdb+ http://kx.com

# SYNOPSIS

    use Kx;

    my $k = Kx->new(host=>'localhost', port=>2222);
    $k->connect() or die "Can't connect to Kdb+ server";

    my $rtn = $k->cmd('til 8');
    my $sum = $k->cmd('{x+y}', $k->int(5)->kval, $k->int(7)->kval);

    my $lst = $k->listof(5, Kx::KI());
    for (0 .. 4) {
        $lst->at($_, $_);
    }
    my $ktyp = Kx::kType($lst->kval);
    my $lst_perl = $lst->val;

# DESCRIPTION

Alpha code.
Create a wrapper around Kdb+ and Q in Perl using the C interface to Kdb+

# EXPORT

None by default.

# METHODS

## New

    my $k = Kx->new(name=>'local22', host=>'localhost', port=>2222);

Create a new Kx object. Set the connection paramaters to conect to 'host'
and 'port' as specified.

No connection is made to the server until you call $k->connect()

If you don't define a name it defaults to 'default'. Each subsequent call
to new() will use the same 'default' connection.

So once you make a connection later calls to new() with the same name
will use the same connection without further connect() calls required.

    my $k = Kx->new(host=>'localhost', port=>2222);
    $k->connect() or die "Can't connect to Kdb+ server";

    # picks up previous default connection to localhost port 2222 and
    # will use it as well.
    my $k1 = Kx->new();

Also username and passwords are supported. Just add the userpass
attribute thus:

    $k = Kx->new(name=>'local22', 
                 host=>'localhost', 
                 port=>2222,
                 userpass=>'user:pass');

## Connect

To connect to the 'default' server.

    unless($k->connect()) {
        warn "Can't connect to Kdb+ server\n";
    }

To connect to a defined server say 'local22'

       unless($k->connect('local22')) {
           warn "Can't connect to local22 Kdb+ server\n";
       }
    

## Environment

There are a number of environment details you can glean from the Kdb+
server you are connected to. They are:

    my $arrayref = $k->tables;     # The tables defined
    my $arrayref = $k->funcs;      # The functions defined
    my $arrayref = $k->views;      # The views defined
    my $arrayref = $k->variables;  # The variables defined
    my $arrayref = $k->memory;     # The memory details \w

    my $dir = $k->cwd;              # The current working directory
    my $dir = $k->chdir($newdir);   # Set the cwd
    my $num = $k->GMToffset;        # Offset from GMT for times

If you make changes that effects these environmental details then call
the env() method to update what is known. This module doesn't continually
hassle the server for these details.

    my @details = $k->env;  # Get the environment from the server

    $details[0] => [ tables     ]
    $details[1] => [ funcs      ]
    $details[2] => [ views      ]
    $details[3] => [ variables  ]
    $details[4] => 'GMToffset'
    $details[5] => 'releasedate'
    $details[6] => 'gmt'
    $details[7] => 'localtime'
    $details[8] => [ memory     ]
    $details[7] => 'cwd'

You can also execute OS commands on the server end and gather the results
like this.

    $arref = $k->oscmd("ls -l /");

## TABLES

You don't need to use this just use the cmd() interface if you like.
However if your lazy like me.... read on

Each of these accessors have a method name starting with 'T'. To help
distinguish them as cooperating methods.

Create a new table in Kdb+ named mytab with 3 columns col1, col2 and
col3. The keys will be on col1 and col3 This equates to the Q command

    # Q command
    q)mytab:([col1:;col3:] col2:)

    # The long winded Perl way
    $k->Tnew(name=>'mytab',keys=>['col1','col3'],cols=>['col2']);

To add data use Tinsert(). Each row is added in the order defined
above. This line adds 1 into col1, 2 into col3 and 3 into col2 as the
keys are always defined before the other columns.

    $k->Tinsert('mytab',1,2,3);

To do a select over a table use Tselect(). Tselect() takes a variable
name as its first argument. The select will be executed and assigned to
the variable you define. This way no data is passed from Kdb+ to the
client until it is needed.

    $k->Tselect('a','select from mytab where col1>4');

This is really just the same as

    # q command
    a:select from mytab where col1>4

To get the details of the stored selection

    my $numrows = $k->Tnumrows('a');
    my $numcols = $k->Tnumcols('a');

This only works on variables that are tables returned from a selection.

Tget() Tindex() Tcol() and Theader() are only useful once you have done a
Tget(). 

Remember it is probably better to only pull back small tables less than
say a few tens of thousand of rows as you'll eat up memory fast.

You may have run a number of Tselects() and now wish to pull back the
data. To do this use Tget()

    $k->Tget('table');   # table must be a table in the server

Tget() can also be used with select type queries that return a table as
their result. It also handles indexed tables better than the cmd()
method.

To get access to random values in the returned table from Tget().

    $val = $k->Tindex(row,col);

This only works for simple tables holding scalars in each row. Don't try
this if the index would point to a mulit-valued list. Actually it sort of
works for lists and when it does $val is an array reference. If you have
troubles use Tcol().

To get the list of column names as Kdb+ knows them.

    my $header = $k->Theader();
        print "@$header\n";

To get the meta data for a table as defined in KDB do this.

    my @meta = $k->Tmeta($table);
    foreach(@meta)
    {
        print "(name type) => (@$_)\n";
    }

To get a Perl reference to a column of data from the table (as K is
column oriented) do the following:

    my $colref = $k->Tcol(0);   # get the zeroth column
    print "Column 0 data is: @$colref\n";

I advise against using this on large columns or tables as it is very
memory inefficent. Better to use $k->cmd() interface to pull back
exactly what you want first. The column reference above is a Perl copy of
the data structure held in Kdb+ memory format in the client. This can be
over 3 times larger in core than the Kdb+ data.

If you need to access data via rows then use $k->Trow(). Given a row
number it will return a reference to the row. The first row is at zero 0.

    my $row = $k->Trow(0);   # get the zeroth row
    print "Row 0 data is: @$row\n";

Finally to delete or remove a table by name from the server:

    $k->Tdelete('table');

Here is a list of the complete table methods we have so far:

    $k->Tnew(name=>'thename',keys=>[],cols=>[]);
    $k->Tinsert('table',1,2,3);
    $k->Tbulkinsert('table',col1=>[],col2=>[],...);
    $k->Tget('select statement');
    $scalar = $k->Tindex($row,$col);
    $arref  = $k->Tcol(2);      # 3rd col vector
    $arref  = $k->Trow(2);      # 3rd row
    $arref  = $k->Theader;
    $x      = $k->Tnumrows;
    $y      = $k->Tnumcols;
    $k->Tselect('table','select statement');
    $k->Tsave('table','file');
    $k->Tappend('table','file');
    $k->Tload('table','file');
    $k->Tdelete('table');

If you want a faster bulk insert function use:

    $k->Tfastbulkinsert('mytab',$col1,$col2,$col3...);

Here col1 col2 etc are infact in core Kdb+ structures and must be in the
same order as the declaration use when you used Tnew(). This is almost 3
times faster than Tbulkinsert but uses more memory in the client. See the
test files that came with this module for more details on how it is used.

## COMMANDS

Execute the code on an already accessable Kdb+ server. The query
is executed and the results are held in K structures in RAM. Example

    $return = $k->cmd('b:til 100');

If you just what to send a command to the Kdb+ server and not wait then
use the following. No return value is provided.

    $k->whenever('b:til 100');

The cmd() method also allows up to two extra arguments that are normally
K objects. You normally call cmd() this way when you have a function to
call. Here is a dodgy example.

    my $data = $k->listof(length($arrsym), Kx::KG());  # list of bytes
    $data->setbin($arrsym);

    $result = $k->cmd('{[x]insert[`mytab](0;x;.z.z)}', $data->kval);

The cmd() function will return a reference to an array if the Q command
returns a list. It will return a simple scalar if the result is a scalar
response from Q. It will return a hash reference if the return result
from Q is either  table/keyed table/dictionary. You need to know what you
are doing so can know what the result is (or use Perl's ref()).

Do not execute queries that return large 'keyed' tables as a copy of the table
in unkeyed form is held to convert to a Perl Hash before being freed.

Note: cmd() does not convert a keyed table to an unkeyed table in memory.
It holds onto what was passed back from KDB+ as is. If you want get at
the underlying K structure and change it use Tget() instead. Tget() will
convert a keyed table to an unkeyed table and hold it in memory.

If you have a Q script that you wish to run against the Kdb+ server you
can use the do(file) method. Any error in your script that is caught will
stop do(file) from proceeding. If you don't care when it is done then use
dolater(file).

Both do() and dolater() don't return anything useful. They just blindly
execute each line of Q against the server. If you want to check each
command and do stuff as a result then use cmd() and check the result.

An example file name foo.txt holds the lines:

    t:([]a:();b:())
    insert[`t](`a;10.70)
    insert[`t](`b;-5.6)
    insert[`t](`c;21.73)

You can run that file by doing this:

    $k->do("foo.txt");

## ATOMS and STRUCTURES

To create Kdb+ atoms locally in RAM use the following calls.

    my $d;
    $d=$k->bool(0);           # boolean
    $d=$k->byte(100);         # char
    $d=$k->char(ord('a'));    # char
    $d=$k->short(20);
    $d=$k->int(70);
    $d=$k->long(93939);
    $d=$k->real(20.44);        # remember 20.44 may look close as a real
    $d=$k->float(20.44);       # should look closer to 20.44 as a float
    $d=$k->sym('mysymbol');    # A Kdb+ symbol
    $d=$k->date(2007,4,22);    # integer encoded date year, month, day
    $d=$k->dt(time());         # Kdb+ datetime from epoch
    $d=$k->tm(100);            # Time type in milliseconds

These allow for fine grained control over the 'type' of K object you
want. If you don't mind particularly about the type conversions then you
can use perl2K() like this.

    $d = $k->perl2K('mysymbol');
    $d = $k->perl2K([qw/this will be a K list of symbols/]);
    $d = $k->perl2K({this => 1, that => 2, 'is a' => 'dict'});

To get a Perl value back from a Kdb+ atom try this;

    my $val = $d->val();

To get the internal value back from a Kdb+ atom try this;

    my $kval = $k->kval;  # used in $x->cmd('func', $kval)

As a further comment on the date() method. When you look at the value
retuned from a date() call it is in epoch seconds.

    my $date = $k->date(2007,4,22);
    print scalar localtime($date->val),"\n";

Further more KDB+ Datetimes are held as a C double in memory. The
integral part is the number of days since 1/1/2000 and the fractional
part is the fraction of the day. You have some control over how datetimes
are returned from KDB+ back into Perl data structures. By default a
conversion to epoch seconds will be made. You can also get epoch seconds
with milliseconds and you can also turn off conversion all together.

    Kx::__Z2epoch(0);   # turn off epoch conversion
    Kx::__Z2epoch(1);   # turn on epoch conversion (default)
    Kx::__Z2epoch(2);   # turn on epoch conversion plus milliseconds

These have immediate effects on how datetimes are converted into Perl
data structures. These do not effect what is held in RAM after a call to
KDB+ has been made, just how they are converted into Perl.

These methods use the underlying functions as listed below. Don't use
these unless you know what your doing. They are listed here for
completeness and so you can use them if you really want. But don't.

    Kx::kb(integer)     => Create boolean 0|1
    Kx::kg(integer)     => Create a byte/char
    Kx::kh(integer)     => Create a short
    Kx::ki(integer)     => Create and integer
    Kx::kj(longval)     => Create a long
    Kx::ke(realval)     => Create a real
    Kx::kf(floatval)    => Create a float
    Kx::kc(charval)     => Create a char from an int ord()
    Kx::ks(symbol)      => Create a symbol from a string
    Kx::kd(date)        => Create a date - See K dates
    Kx::kz(datetime)    => Create a datetime - See K dates
    Kx::kt(time)        => Create a time

    Kx::p2k($ref)       => return a K structure describing the Reference
    Kx::k2p(K)          => return a Perl structure from a Kdb+ structure

    Kx::k2pscalar(K)    => return a scalar from a Kdb+ atom
    Kx::k2parray(K)     => return an array from a Kdb+ list
    Kx::k2phash(K)      => return a hash from a Kdb+ dict/table

    Kx::phash2k($href)  => return a Kdb+ dict from a Perl hash ref
    Kx::parray2k($aref) => return a Kdb+ list from a Perl array ref
    Kx::pscalar2k($srf) => return a Kdb+ atom from a Perl scalar ref

Example:

    # Simple create
    my $bool = $k->bool(0);
    print "My boolean in K is ",$bool->val,"\n";

## LISTS

These list functions create in memory local lists outside of any 'q'
running process. These will allow you to create very large simple lists
without blowing out all your memory.

To create a simple Kdb+ list of a single type use the listof() function.
The type of the list is passed in as the second aregument and can be one
of:

    Kx::KC()  char
    Kx::KD()  date yyyy mm dd
    Kx::KE()  real
    Kx::KF()  float
    Kx::KG()  byte
    Kx::KH()  short
    Kx::KI()  integer
    Kx::KJ()  long
    Kx::KM()  month
    Kx::KS()  symbol (internalised string)
    Kx::KT()  time
    Kx::KU()  minute
    Kx::KV()  second
    Kx::KZ()  datetime epoch seconds

Example simple lists:

    my $list = $k->listof(20,Kx::KS());      # List of 20 symbols
    for( my $i=0; $i < 20; $i++)
    {
        $list->at($i,"symbol$i");
    }

    # To get at the 4th element
    my $sym = $list->at(3);     # symbol3

    my $perl_list = $list->list;
    print "Symbols are @$perl_list\n";

    # dates
    $d = $k->listof(20,Kx::KD());
    for( my $i=0; $i < 20; $i++)
    {
        $d->at($i,2007,4,$i+1);  # 20070401 -> 20070421
    }

    # Add an extra date to the end of the list
    my $day = $k->date(2007,4,30);
    $d->joinatom($day->kval);

There is also another method defined setbin()  that sets binary
data into a list of bytes. You can use this to save serialised Perl
data structures into Kdb+ tables (much like a blob or text field in SQL
DBs).  Here is an example:

    use Kx;
    use Compress::Zlib qw/compress uncompress/;
    use Data::Dumper;
    $Data::Dumper::Indent = 0; # no newlines, important
    
    my $k = Kx->new(host=>"localhost", port=>2222, check_for_errors=>1);
    $k->connect() or die "Can't connect to Kdb+ server";
    
    # create new table in q
    $k->Tnew(name=>'mytab',cols=>[qw/id data ts/]);
    
    # Build a large complicated Perl structure.
    my $arr = { a=>['a','b','c',1,2,3], b=>'this is a test'};
    for (0..10000) {
        $arr->{$_} = {$_ => $_};
        $arr->{"a$_"} = [$_, $_];
    }
    
    # Serialise it as a compressed piece of data
    my $arrsym =  Dumper($arr);
    print "Dumper size is: ", length $arrsym, "\n";
    $arrsym = compress( $arrsym );
    print "Compress Dumper size is: ", length $arrsym, "\n";
    
    # An in memory Kdb+ list of bytes to hold the compressed data
    my $data = $k->listof(length($arrsym),Kx::KG());  # list of length bytes
    $data->setbin($arrsym);
    
    # Insert it into a table using a function call.
    $k->cmd('{[x]insert[`mytab](0;x;.z.z)}',$data->kval);
    
    # Select a single row from the table, and return it's data
    $binary = $k->cmd('(select data from mytab where id=0)[0;`data]');
    
    # Get the data back into Perl string form
    $arrsym = uncompress($binary);
    #print $arrsym,"\n";
    
    # Eval the string into a Perl data structure the hard way
    my $VAR1;
    eval $arrsym;
    print $VAR1->{'b'},"\n";

## Mixed Lists

    # The zero in line below says its to be a mixed list
    my $list = $k->listof(40,0); # mixed list 40 elements
    $list->at(0,$k->float(22.22));

    $list->at(1,$k->sym('this is a test'));
    .
    .
    $list->at(39,$k->date(2007,2,28));

This is handy for creating multiple arguments to a KDB+ function call.

## Utility Methods

$k->dump0() will return a string describing the under lying K structure.

Kx::dump($k) will print out the K structure of $k

$sym = Kx::makesym("string") will convert a simple string into a quoted
symbol suitable for usage in KDB+

make\_C() will convert its argument into a suitable string quoted
as a KDB+ character list.

    my $c = Kx::make_C("now is\tthe \n time for \n help");

There is also make\_s():

    my $sym = Kx::make_s("a symbol"); # `$"a symbol"
    my $sym = Kx::make_s(undef);      # a null symbol `

# Kx::LIST

You may wish to tie a Perl array to a Kdb+ variable. Well, you can do
that as well. Try something like this:

    use Kx;
    
    my %config = (
        host=>"localhost",
        port=>2222,
        userpass=>'user:pass',    # optional
        type=>'symbol',
        list=>'d',
        create=>1
    );
    tie(@a, 'Kx::LIST', %config);
    
    # push lost of stuff on an array
    my @array = (qw/aaaa bbbbb ccccc ddddddddd e f j h i j k l/) x 30000
    ;
    push(@a,@array);
    push(@a,@array);
    push(@a,@array);
    print "\@a has ", scalar(@a)," elements\n";
    
    # Store
    $a[3] = "Help me";
    print "Elementt 3 is ",$a[3],"\n";

All the functions defined in perltie for lists are included.

Note: 'type' is a Kdb+ type as defined in Types below - it is the
type for the array.  Only simple types are allowed at the moment.

# Kx::HASH

You may wish to tie a Perl hash to a Kdb+ variable. Well, you can do
that as well. Try something like this:

    use Kx;

    my %config = (
            host=>"localhost",
            port=>2222,
            userpass=>'user:pass', # optional
            ktype=>'symbol',
            vtype=>'int',
            dict=>'x',
            create=>1
    );
    tie(%x, 'Kx::HASH', %config);
    
    print "Size of hash x is :". scalar %x ."\n";
    for(0..5) {
        $x{"a$_"} = $_;
    }
    
    %y = %x;
    
    for(0..5) {
        print $y{"a$_"}," " if exists $y{"a$_"};
    }
    print "\n";
    
    while(($k,$v) = each %x) {
        print "Key=>$k is $v\n";
    }
    untie(%x);

All the functions defined in perltie for hashs are included.

Note: ktype is a Kdb+ type as defined in Types below - it is the
'key' type for the hash. vtype is also defined in Types - it is the
value type. Only simple types are allowed at the moment.

# SEE ALSO

http://kx.com

http://code.kx.com

See the test code under the 't' directory of this module for more details
on how to call each method.

# AUTHORS

- Mark Pfeiffer, <markpf@mlp-consulting.com.au>
- Stephan Loyd, <stephanloyd9@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2007 by Mark Pfeiffer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

This code is not affiliated with KxSystems in anyway. It is just a simple
interface to their code. Any functionality that is of any use is due to
the hard work of the people at KxSystems.

This is Alpha code. Use at your own risk. It is availble only for testing
at the moment. It has not been fully tested. For example nulls, inf and
the like. Your kms may vary.

If this code is useful then please drop me a line and let me know. I
would also like to be acknowledged in any products you may make from
this. I get a bit of a buzz out of it.

The `LICENSE` file in the package is the Perl 5 license.

# BUGS

Plenty and to be expected. Please send me any bugs you find. Patches
are even better and will always be acknowledged.

Once the code has been tested for a while I'll move it to beta. Don't
hold your breath though.

All spelling mistakes are mine ;-)

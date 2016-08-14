use 5.008;
use ExtUtils::MakeMaker;

# here we check out if we have our prerequisites
unless(-f 'libkdb.a')
{
	print 
"I can't see a libkdb.a
You need to download c.o from http://kx.com/q/ and build a library I can
use (libkdb.a). Once you have that rerun perl Makefile.PL

To build a library try something like this.

        ar -r libkdb.a c.o
or
        libtool -static -o libkdb.a c.o

perl Makefile.PL
make
make test     # you must have a 'q' process running on port 2222 (q -p 2222)
make install

";
	ExtUtils::MakeMaker::WriteEmptyMakefile();
	exit;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Kx',
    VERSION_FROM      => 'lib/Kx.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Kx.pm', # retrieve abstract from module
       AUTHOR         => 'mark pfeiffer <markpf at mlp-consulting .com>') : ()),
    LIBS              => ['-L. -lkdb'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    #OBJECT            => '$(c.o)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(KB KC KD KE KF KG KH KI KJ KM KS KT KU KV KZ XD XT));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Kx',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

       abs VALUE
       abs Returns the absolute value of its argument.  If VALUE is omitted,
       accept NEWSOCKET,GENERICSOCKET
       alarm SECONDS
       alarm
       atan2 Y,X
       bind SOCKET,NAME
       binmode FILEHANDLE, LAYER
       binmode FILEHANDLE
       bless REF,CLASSNAME
       bless REF
       break
       caller EXPR
       caller
       chdir EXPR
       chdir FILEHANDLE
       chdir DIRHANDLE
       chdir
       chmod LIST
       chomp VARIABLE
       chomp( LIST )
       chomp
       chop VARIABLE
       chop( LIST )
       chop
       chown LIST
       chr NUMBER
       chr Returns the character represented by that NUMBER in the character
       chroot FILENAME
       chroot
       close FILEHANDLE
       close
       closedir DIRHANDLE
       connect SOCKET,NAME
       continue BLOCK
       continue
       cos EXPR
       cos Returns the cosine of EXPR (expressed in radians).  If EXPR is
       crypt PLAINTEXT,SALT
       dbmclose HASH
       dbmopen HASH,DBNAME,MASK
       defined EXPR
       defined
       delete EXPR
       die LIST
       do BLOCK
       do SUBROUTINE(LIST)
       do EXPR
       dump LABEL
       dump
       each HASH
       each ARRAY
       eof FILEHANDLE
       eof ()
       eof Returns 1 if the next read on FILEHANDLE will return end of file,
       eval EXPR
       eval BLOCK
       eval
       exec LIST
       exec PROGRAM LIST
       exists EXPR
       exit EXPR
       exit
       exp EXPR
       exp Returns _ (the natural logarithm base) to the power of EXPR.  If
       fcntl FILEHANDLE,FUNCTION,SCALAR
       fileno FILEHANDLE
       flock FILEHANDLE,OPERATION
       fork
       format
       formline PICTURE,LIST
       getc FILEHANDLE
       getc
       getlogin
       getpeername SOCKET
       getpgrp PID
       getppid
       getpriority WHICH,WHO
       getpwnam NAME
       getgrnam NAME
       gethostbyname NAME
       getnetbyname NAME
       getprotobyname NAME
       getpwuid UID
       getgrgid GID
       getservbyname NAME,PROTO
       gethostbyaddr ADDR,ADDRTYPE
       getnetbyaddr ADDR,ADDRTYPE
       getprotobynumber NUMBER
       getservbyport PORT,PROTO
       getpwent
       getgrent
       gethostent
       getnetent
       getprotoent
       getservent
       setpwent
       setgrent
       sethostent STAYOPEN
       setnetent STAYOPEN
       setprotoent STAYOPEN
       setservent STAYOPEN
       endpwent
       endgrent
       endhostent
       endnetent
       endprotoent
       endservent
       getsockname SOCKET
       getsockopt SOCKET,LEVEL,OPTNAME
       glob EXPR
       glob
       gmtime EXPR
       gmtime
       goto LABEL
       goto EXPR
       goto &NAME
       grep BLOCK LIST
       grep EXPR,LIST
       hex EXPR
       hex Interprets EXPR as a hex string and returns the corresponding
       import LIST
       index STR,SUBSTR,POSITION
       index STR,SUBSTR
       int EXPR
       int Returns the integer portion of EXPR.  If EXPR is omitted, uses $_.
       ioctl FILEHANDLE,FUNCTION,SCALAR
       join EXPR,LIST
       keys HASH
       keys ARRAY
       kill SIGNAL, LIST
       last LABEL
       last
       lc EXPR
       lc  Returns a lowercased version of EXPR.  This is the internal
       lcfirst EXPR
       lcfirst
       length EXPR
       length
       link OLDFILE,NEWFILE
       listen SOCKET,QUEUESIZE
       local EXPR
       localtime EXPR
       localtime
       lock THING
       log EXPR
       log Returns the natural logarithm (base _) of EXPR.  If EXPR is
       lstat EXPR
       lstat
       m// The match operator.  See "Regexp Quote‐Like Operators" in perlop.
       map BLOCK LIST
       map EXPR,LIST
       mkdir FILENAME,MASK
       mkdir FILENAME
       mkdir
       msgctl ID,CMD,ARG
       msgget KEY,FLAGS
       msgrcv ID,VAR,SIZE,TYPE,FLAGS
       msgsnd ID,MSG,FLAGS
       my EXPR
       my TYPE EXPR
       my EXPR : ATTRS
       my TYPE EXPR : ATTRS
       next LABEL
       next
       no MODULE VERSION LIST
       no MODULE VERSION
       no MODULE LIST
       no MODULE
       no VERSION
       oct EXPR
       oct Interprets EXPR as an octal string and returns the corresponding
       open FILEHANDLE,EXPR
       open FILEHANDLE,MODE,EXPR
       open FILEHANDLE,MODE,EXPR,LIST
       open FILEHANDLE,MODE,REFERENCE
       open FILEHANDLE
       opendir DIRHANDLE,EXPR
       ord EXPR
       ord Returns the numeric (the native 8−bit encoding, like ASCII or
       our EXPR
       our TYPE EXPR
       our EXPR : ATTRS
       our TYPE EXPR : ATTRS
       pack TEMPLATE,LIST
       package NAMESPACE VERSION
       package NAMESPACE
       pipe READHANDLE,WRITEHANDLE
       pop ARRAY
       pop Pops and returns the last value of the array, shortening the array
       pos SCALAR
       pos Returns the offset of where the last "m//g" search left off for the
       print FILEHANDLE LIST
       print LIST
       print
       printf FILEHANDLE FORMAT, LIST
       printf FORMAT, LIST
       prototype FUNCTION
       push ARRAY,LIST
       q/STRING/
       qq/STRING/
       qx/STRING/
       qw/STRING/
       qr/STRING/
       quotemeta EXPR
       quotemeta
       rand EXPR
       rand
       read FILEHANDLE,SCALAR,LENGTH,OFFSET
       read FILEHANDLE,SCALAR,LENGTH
       readdir DIRHANDLE
       readline EXPR
       readline
       readlink EXPR
       readlink
       readpipe EXPR
       readpipe
       recv SOCKET,SCALAR,LENGTH,FLAGS
       redo LABEL
       redo
       ref EXPR
       ref Returns a non‐empty string if EXPR is a reference, the empty string
       rename OLDNAME,NEWNAME
       require VERSION
       require EXPR
       require
       reset EXPR
       reset
       return EXPR
       return
       reverse LIST
       rewinddir DIRHANDLE
       rindex STR,SUBSTR,POSITION
       rindex STR,SUBSTR
       rmdir FILENAME
       rmdir
       s///
       say FILEHANDLE LIST
       say LIST
       say Just like "print", but implicitly appends a newline.  "say LIST" is
       scalar EXPR
       seek FILEHANDLE,POSITION,WHENCE
       seekdir DIRHANDLE,POS
       select FILEHANDLE
       select
       select RBITS,WBITS,EBITS,TIMEOUT
       semctl ID,SEMNUM,CMD,ARG
       semget KEY,NSEMS,FLAGS
       semop KEY,OPSTRING
       send SOCKET,MSG,FLAGS,TO
       send SOCKET,MSG,FLAGS
       setpgrp PID,PGRP
       setpriority WHICH,WHO,PRIORITY
       setsockopt SOCKET,LEVEL,OPTNAME,OPTVAL
       shift ARRAY
       shift
       shmctl ID,CMD,ARG
       shmget KEY,SIZE,FLAGS
       shmread ID,VAR,POS,SIZE
       shmwrite ID,STRING,POS,SIZE
       shutdown SOCKET,HOW
       sin EXPR
       sin Returns the sine of EXPR (expressed in radians).  If EXPR is
       sleep EXPR
       sleep
       socket SOCKET,DOMAIN,TYPE,PROTOCOL
       socketpair SOCKET1,SOCKET2,DOMAIN,TYPE,PROTOCOL
       sort SUBNAME LIST
       sort BLOCK LIST
       sort LIST
       splice ARRAY,OFFSET,LENGTH,LIST
       splice ARRAY,OFFSET,LENGTH
       splice ARRAY,OFFSET
       splice ARRAY
       split /PATTERN/,EXPR,LIMIT
       split /PATTERN/,EXPR
       split /PATTERN/
       split
       sprintf FORMAT, LIST
       sqrt EXPR
       sqrt
       srand EXPR
       srand
       stat FILEHANDLE
       stat EXPR
       stat DIRHANDLE
       stat
       state EXPR
       state TYPE EXPR
       state EXPR : ATTRS
       state TYPE EXPR : ATTRS
       study SCALAR
       study
       sub NAME BLOCK
       sub NAME (PROTO) BLOCK
       sub NAME : ATTRS BLOCK
       sub NAME (PROTO) : ATTRS BLOCK
       substr EXPR,OFFSET,LENGTH,REPLACEMENT
       substr EXPR,OFFSET,LENGTH
       substr EXPR,OFFSET
       symlink OLDFILE,NEWFILE
       syscall NUMBER, LIST
       sysopen FILEHANDLE,FILENAME,MODE
       sysopen FILEHANDLE,FILENAME,MODE,PERMS
       sysread FILEHANDLE,SCALAR,LENGTH,OFFSET
       sysread FILEHANDLE,SCALAR,LENGTH
       sysseek FILEHANDLE,POSITION,WHENCE
       system LIST
       system PROGRAM LIST
       syswrite FILEHANDLE,SCALAR,LENGTH,OFFSET
       syswrite FILEHANDLE,SCALAR,LENGTH
       syswrite FILEHANDLE,SCALAR
       tell FILEHANDLE
       tell
       telldir DIRHANDLE
       tie VARIABLE,CLASSNAME,LIST
       tied VARIABLE
       time
       times
       tr///
       truncate FILEHANDLE,LENGTH
       truncate EXPR,LENGTH
       uc EXPR
       uc  Returns an uppercased version of EXPR.  This is the internal
       ucfirst EXPR
       ucfirst
       umask EXPR
       umask
       undef EXPR
       undef
       unlink LIST
       unlink
       unpack TEMPLATE,EXPR
       unpack TEMPLATE
       untie VARIABLE
       unshift ARRAY,LIST
       use Module VERSION LIST
       use Module VERSION
       use Module LIST
       use Module
       use VERSION
       utime LIST
       values HASH
       values ARRAY
       vec EXPR,OFFSET,BITS
       wait
       waitpid PID,FLAGS
       wantarray
       warn LIST
       write FILEHANDLE
       write EXPR
       write
       y///

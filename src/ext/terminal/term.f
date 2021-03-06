\ term.f        - termifo loading
\ ------------------------------------------------------------------------

  .( term.f )

\ ------------------------------------------------------------------------

\ this file loads the correct terminfo file for the terminal being used
\ and sets pointers to the various sections within that file for use by
\ the definitions within terminfo.f

\ ------------------------------------------------------------------------

  vocabulary terminal terminal definitions

\ ------------------------------------------------------------------------
\ the below path assumes your distribution follows the fhs

\ if you are using a debian based distribution then you will need to copy
\ every terminfo file out of /lib/terminfo into /usr/share/terminfo where
\ they should never have been moved out of.  The decision to MOVE those
\ files instead of copying them is one of the most stupid things I have
\ ever seen any linux distribution do.

\ I could add code to this file so it searches both the /usr/share and
\ the /lib directories for terminfo files but all that really does is
\ force me to add duct tape to my code for their stupidness and if i did
\ that everywhere things like this happen I would be as bloated as
\ the libncurses library needs to be.  that was NOT a diss on ncurses.

  <headers

  create info-file
    (,')  /usr/share/terminfo/'
  here (,') x/'
  here 0 , 0 , 0 w,

  align,

  var info-name
  var info-letter

\ ------------------------------------------------------------------------

  create env_term  ," TERM"

\ ------------------------------------------------------------------------

  0 var terminfo            \ address of terminfo data
  0 var tsize               \ size of memory mapping

\ we never actually unmap the terminfo file so we dont realy need to
\ remember the size of the mapping

\ ------------------------------------------------------------------------
\ escape sequences compiled to this buffer

  0 var $buffer             \ output string compile buffer
  0 var #$buffer            \ number of characters compiled to $buffer

\ ------------------------------------------------------------------------
\ pointers to each section within terminfo file

\ these are realy constants but we dont kmow their values yet

  0 var t-names             \ names section
  0 var t-bool              \ bool section
  0 var t-numbers           \ numbers section
  0 var t-strings           \ string section (offsets within following)
  0 var t-table             \ string table

\ -----------------------------------------------------------------------
\ various buffers used when parsing escape sequence format strings

  0 var f$                  \ format string parse address
  0 var params              \ format string parameters
  0 var a-z                 \ format string variables
  0 var A-Z                 \ format string variables

\ ------------------------------------------------------------------------
\ an evil forward reference

  defer >format             \ store one sequence in output buffer

\ ------------------------------------------------------------------------

  headers>

  defer .$buffer            \ write whole output buffer (to display?)

\ ------------------------------------------------------------------------

: 0$buffer off> #$buffer ;

\ ------------------------------------------------------------------------
\ gnome terminals have black = 9 just to be stupid (erm different i mean)

  <headers

\ ------------------------------------------------------------------------
\ create full path to terminfo file

\ this code ignores the fact that a user can have a ~/.terminfo directory

: (get-info)    ( a1 n1 ---  )
  over c@ info-letter c!    \ first letter of term name = part of path
  dup info-file c@ + 2+     \ compute total length of info file path
  info-file c!              \ length of path and file name
  info-name swap cmove ;    \ append name to path

\ ------------------------------------------------------------------------
\ read terminfo file (memory map it)

: read-info
  0 info-file fopen         \ open terminfo file for read
  dup -1 =
  if
    ." Unknown TERM: "
    info-file count type    \ display unknown terminfo file
    bye                     \ and get out
  then

  dup                       \ keep fd so we can close the file
  1 dup fmmap               \ map shared and prot read
  !> tsize !> terminfo
  fclose ;                  \ close the file but keep the mapping

\ ------------------------------------------------------------------------
\ allocate a buffer of n1 bytes in size

: ?alloc        ( n1 --- a1 )
  allocate ?exit
  ." Cannot Allocate Terminal Buffers"
  bye ;

\ ------------------------------------------------------------------------
\ alloate terminal output buffer

: alloc-buffers
  32768 ?alloc !> $buffer   \ sequence output buffer
  36    ?alloc !> params    \ format string parameter buffer
  104   ?alloc !> a-z       \ format string variable buffers
  104   ?alloc !> A-Z ;

\ ------------------------------------------------------------------------
\ initialize pointers to each section within terminfo file

: init-pointers
  terminfo dup>r 12 +           !> t-names
  r@ 2+ w@ t-names +            !> t-bool
  r@ 4+ w@ t-bool + dup 1 and + !> t-numbers
  r@ 6 + w@ 2* t-numbers +      !> t-strings
  r> 8 + w@ 2* t-strings +      !> t-table ;

\ ------------------------------------------------------------------------
\ quits forth if terminfo file is corrupted

: valid?
  terminfo w@ \0432 = ?exit
  ." Terminfo - Bad Magic!"
  bye ;

\ ------------------------------------------------------------------------
\ read terminfo file and calculate addresses for each section therein

: get-info
  defers default            \ add to default init chain
  env_term getenv           \ did anyone bother to set $term env ?
  if
    (get-info) read-info    \ create full path to terminfo file and read
    valid?                  \ test sanity of terminfo file
    alloc-buffers           \ allocate buffers
    init-pointers           \ initialize pointers to each section
  else
    ." Terminfo - I'm confused (or you are)"
    bye
  then ;

\ ------------------------------------------------------------------------
\ store n1 parameters in paramter table

: >params       ( ... n1 --- )
  params 36 erase           \ zero all parameters
  ?dup 0= ?exit             \ would this ever happen?
  for
    params r@ []!
  nxt ;

\ ------------------------------------------------------------------------
\ translate alt charset character prior to emit (not done automatically)

  headers>

: >acsc      ( c1 --- c2 )
  t-strings 292 + w@
  t-table + 60 pluck scan
  if
    1+ c@ nip
  else
    drop
  then ;

\ ========================================================================

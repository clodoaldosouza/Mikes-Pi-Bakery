'' ===========================================================================
''
''  File: WMF_GuessMyNumber_010.Spin 
''
''  Modification History
''
''  Author:     Andre' LaMothe 
''  Copyright (c) Andre' LaMothe / Parallax Inc.
''  See end of file for terms of use
''  Version:    1.0
''  Date:       2/20/2011
''
''  Comments: This demo shows off user input from the keyboard. One of the most overlooked
''  problems graphics is that its difficult to draw text, graphics, but sometimes even
''  more difficult to get user input! This is due to the fact, that there isn't a nice
''  line editor, console, terminal system that understands delete, backspace, the arrow
''  keys and so forth -- we actually have to write one that supports these functions.
''  
''  With that in mind, this little demo shows off a local method that accomplishes
''  single line input with modest editing, you can delete and backspace. The name of
''  the method is GetStringTerm(...) and relies on the terminal services driver
''  to draw characters to the VGA screen (which itself relies on the VGA drivers).
''
''  In any event, this local method is a great way to get user input for your applications.

''  Requires: This demo, like the majority of VGA demos requires a Propeller platform
''  with both a mouse and keyboard as well as VGA output. You can adjust the pins for
''  the devices below in the CON section. This demo was developed using the standard
''  Propeller Demo board with a 5 Mhz, xtal. If you have something different you will
''  have to make the appropriate changes.  
''
'' ===========================================================================


CON
' -----------------------------------------------------------------------------
' CONSTANTS, DEFINES, MACROS, ETC.   
' -----------------------------------------------------------------------------

  ' set speed to 80 MHZ, 5.0 MHZ xtal, change this if you are using
  ' other XTAL speeds
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ' import some constants from the Propeller Window Manager
  VGACOLS = WMF#VGACOLS
  VGAROWS = WMF#VGAROWS

  ' set these constants based on the Propeller device you are using
  VGA_BASE_PIN      = 16        'VGA pins 16-23
  
  MOUSE_DATA_PIN    = 24        'MOUSE data pin
  MOUSE_CLK_PIN     = 25        'MOUSE clock pin

  KBD_DATA_PIN      = 26        'KEYBOARD data pin
  KBD_CLK_PIN       = 27        'KEYBOARD clock pin 

  ' ASCII codes for ease of character and string processing
  ASCII_A      = 65
  ASCII_B      = 66
  ASCII_C      = 67
  ASCII_D      = 68
  ASCII_E      = 69
  ASCII_F      = 70
  ASCII_G      = 71
  ASCII_H      = 72
  ASCII_O      = 79  
  ASCII_P      = 80
  ASCII_Z      = 90
  ASCII_0      = 48
  ASCII_9      = 57
  ASCII_LEFT   = $C0
  ASCII_RIGHT  = $C1
  ASCII_UP     = $C2
  ASCII_DOWN   = $C3 
  ASCII_BS     = $C8 ' backspace
  ASCII_DEL    = $C9 ' delete
  ASCII_LF     = $0A ' line feed 
  ASCII_CR     = $0D ' carriage return
  ASCII_ESC    = $CB ' escape
  ASCII_HEX    = $24 ' $ for hex
  ASCII_BIN    = $25 ' % for binary
  ASCII_LB     = $5B ' [ 
  ASCII_SEMI   = $3A ' ; 
  ASCII_EQUALS = $3D ' = 
  ASCII_PERIOD = $2E ' .
  ASCII_COMMA  = $2C ' ,
  ASCII_SHARP  = $23 ' #
  ASCII_NULL   = $00 ' null character
  ASCII_SPACE  = $20 ' space
  ASCII_TAB    = $09 ' horizontal tab

' box drawing characters
  ASCII_HLINE = 14 ' horizontal line character
  ASCII_VLINE = 15 ' vertical line character
  ASCII_TOPLT = 10 ' top left corner character
  ASCII_TOPRT = 11 ' top right corner character
  ASCII_TOPT  = 16 ' top "t" character
  ASCII_BOTT  = 17 ' bottom "t" character
  ASCII_LTT   = 18 ' left "t" character
  ASCII_RTT   = 19 ' right "t" character
  ASCII_BOTLT = 12 ' bottom left character
  ASCII_BOTRT = 13 ' bottom right character
  ASCII_DITHER = 24 ' dithered pattern for shadows
  NULL         = 0 ' NULL pointer


OBJ
  '---------------------------------------------------------------------------
  ' Propeller Windows GUI object(s) 
  '---------------------------------------------------------------------------
  
  WMF           : "WMF_Terminal_Services_010" ' include the terminal services driver which includes the VGA driver itself 
  kbd           : "Keyboard_011"              ' include the standard 2-pin keyboard driver
  mouse         : "Mouse_011"                 ' include the standard 2-pin mouse driver 

VAR
' -----------------------------------------------------------------------------
' DECLARED VARIABLES, ARRAYS, ETC.   
' -----------------------------------------------------------------------------

  byte  gVgaRows, gVgaCols ' convenient globals to store number of columns and rows

  byte  gStrBuff1[64]      ' some string buffers
  byte  gStrBuff2[64]

  ' these data structures contains two cursors in the format [x,y,mode]
  ' these are passed to the VGA driver, so it can render them over the text in the display
  ' like "hardware" cursors, that don't disturb the graphics under them. We can use them
  ' to show where the text cursor and mouse cursor is
  ' The data structure is 6 contiguous bytes which we pass to the VGA driver ultimately
  
  byte  gTextCursX, gTextCursY, gTextCursMode        ' text cursor 0 [x0,y0,mode0] 
  byte  gMouseCursX, gMouseCursY, gMouseCursMode     ' mouse cursor 1 [x1,y1,mode1] 

  byte  gMouseButtons                                ' buttons for mouse 
  long  gVideoBufferPtr                              ' holds the address of the video buffer passed back from the VGA driver
  long  gRandSeed                                    ' used to generate random numbers  

CON
' -----------------------------------------------------------------------------
' MAIN ENTRY POINT   
' -----------------------------------------------------------------------------
PUB Start | randNumber, guessNumber

  ' first step create the GUI itself
  CreateAppGUI

    ' set terminal cursor initial position a little from top
    WMF.GotoXYTerm( 0, 3)
    WMF.StringTermLn(string("VGA Terminal Services Demo | Guess My Number | (c) Parallax 2011"))
    

  ' MAIN EVENT LOOP - this is where you put all your code in an infinite loop...  
  repeat
     
    ' main code goes here................
 
    ' Guess my number game to illustrate user input and string to numeric conversion
    WMF.NewlineTerm
    WMF.StringTermLn(string("I am thinking of a number from 1 to 100..."))

    ' get a new random number from generator
    ' || is absolute value operator, ? uses the seed as the value for a LFSR (linear feedback shift register)
    ' refer to Propeller Manual for more info on the ? operator
    randNumber := 1 + ||(?gRandSeed // 100) 

    ' start guess off incorrectly
    guessNumber := -1

    ' enter into loop, once in here, the code blocks waiting for user input and the mouser cursor doens't update anymore
    ' this is to be expected, and purposely shown here.
    repeat while ( guessNumber <> randNumber )
      WMF.NewlineTerm
      WMF.StringTerm(string("Guess my number?"))

      ' get user input with local method       
      GetStringTerm( @gStrBuff1, 4)

      ' convert input from string to decimal (here you might want to do input validation as well)
      ' this atoi is very smart, it can convert decimal, hex $, binary % numbers!
      guessNumber := WMF.atoi( @gStrBuff1, 4 )
   
      ' test input
      if ( guessNumber > randNumber )
        WMF.NewlineTerm
        WMF.StringTerm(string("Too high!"))
      elseif ( guessNumber < randNumber )
        WMF.NewlineTerm
        WMF.StringTerm(string("Too Low!"))
      else
        WMF.NewlineTerm
        WMF.StringTermLn(string("Correct - You must be a genius!"))      
 
' end PUB ---------------------------------------------------------------------

PUB CreateAppGUI | retVal, index 
' This functions creates the entire user interface for the application and does any other
' static initialization you might want, notice we start both a mouse and keyboard driver
' if you do NOT want one or the other you can comment our the driver calls to start them
' but it will break some of the demos. Thus, ideally use a Propeller platform that has both
' a keyboard and mouse to get the most out of the series of demos. You can always remove one
' input device in your final applications, but its nice to have them both for illustrative
' purposes to show certain GUI concepts
 
  ' text cursor starting position and as blinking underscore
  ' we aren't going to use the text cursor in this demo, so put it upper left
  ' and just let it blink, we could hide it, but I want to show that it overlays
  ' anything that happpens.  
  gTextCursX     := 0                              
  gTextCursY     := 0                              
  gTextCursMode  := %110       

  ' set mouse cursor position and as solid block
  ' we aren't going to use the mouse cursor in this demo, so put it in center of screen
  ' and just let it sit there, we could hide it, but I want to show that it overlays
  ' anything that happpens.  
  gMouseCursX    := VGACOLS/2                              
  gMouseCursY    := VGAROWS/2                              
  gMouseCursMode := %001 

  ' start the mouse
  mouse.start( MOUSE_DATA_PIN, MOUSE_CLK_PIN )

  ' set boundaries
  mouse.bound_limits(0, 0, 0, VGACOLS - 1, VGAROWS - 1, 0)

  ' adjust speed/sensitivity (note minus value on 2nd parm inverts the axis as well)
  mouse.bound_scales(8, -8, 0)           

  'mouse starting position
  mouse.bound_preset(VGACOLS/2, VGAROWS/2, 0)            

  ' start the keyboard
  kbd.start( KBD_DATA_PIN, KBD_CLK_PIN )

  ' now start the VGA driver and terminal services 
  retVal := WMF.Init(VGA_BASE_PIN, @gTextCursX )

  ' rows encoded in upper 8-bits. columns in lower 8-bits of return value, redundant code really
  ' since we pull it in with a constant in the first CON section, but up to you! 
  gVgaRows := ( retVal & $0000FF00 ) >> 8
  gVgaCols := retVal & $000000FF

  ' VGA buffer encoded in upper 16-bits of return value
  gVideoBufferPtr := retVal >> 16 

  '---------------------------------------------------------------------------
  'setup screen colors
  '---------------------------------------------------------------------------
 
  ' the VGA driver VGA_HiRes_Text_*** only has 2 colors per character
  ' (one for foreground, one for background). However,each line/row on the screen
  ' can have its OWN set of 2 colors, thus as long as you design your interfaces
  ' "vertically" you can have more apparent colors, nonetheless, on any one row
  ' there are only two colors. The method call below fills the color table up
  ' for the specified foreground and background colors from the set of "themes"
  ' found in the PWM_Terminal_Services_*** driver. These are nothing more than
  ' some pre-computed color constants that look "good" and if you are color or
  ' artistically challenged will help you make your GUIs look clean and professional.
  WMF.ClearScreen( WMF#CTHEME_ATARI_C64_FG, WMF#CTHEME_ATARI_C64_BG )               

  ' seed the random number generator with something random such as signals on inputs
  ' this works quite well!
  repeat index from 0 to 1024
    gRandSeed += INA   

  ' return to caller
  return
   
' end PUB ---------------------------------------------------------------------    

CON
' -----------------------------------------------------------------------------
' USER TEXT INPUT METHOD(s)   
' -----------------------------------------------------------------------------

PUB GetStringTerm(pStringPtr, pMaxLength) | length, key
{{
DESCRIPTION: This simple method is a single line editor that allows user to enter keys from the keyboard
and then echos them to the screen, when the user hits <ENTER> | <RETURN> the method
exits and returns the string. The method has simple editing and allows <BACKSPACE> to
delete the last character, that's it! The method outputs to the terminal.

PARMS: pStringPTr - pointer to storage for input string.
       pMaxLength - maximum length of string buffer.

RETURNS: pointer to string, empty string if user entered nothing.

}}

  ' current length of string buffer
  length := 0  

  ' draw cursor
  repeat 

    ' draw cursor
    WMF.OutTerm( "_" )
    WMF.OutTerm( $08 )
  
    ' wait for keypress 
    repeat while (kbd.gotkey == FALSE)

    ' user entered a key process it

    ' get key from buffer
    key := kbd.key
     
    case key
       ASCII_LF, ASCII_CR: ' return    
 
        ' null terminate string and return
        byte [pStringPtr][length] := ASCII_NULL
     
        return( pStringPtr )

       ASCII_BS, ASCII_DEL, ASCII_LEFT: ' backspace (edit)

         if (length > 0)
           ' move cursor back once to overwrite last character on screen
           WMF.OutTerm( ASCII_SPACE )
           WMF.OutTerm( $08 )          
           WMF.OutTerm( $08 )
           
           ' echo character
           WMF.OutTerm( ASCII_SPACE )
           WMF.OutTerm( $08 )
         
           ' decrement length
           length--
 
       other:    ' all other cases
         ' insert character into string 
         byte [pStringPtr][length] := key

         ' update length
         if (length < pMaxLength )
           length++
         else
           ' move cursor back once to overwrite last character on screen
           WMF.OutTerm( $08 )          

         ' echo character
         WMF.OutTerm( key )
     
' end PUB ----------------------------------------------------------------------



CON
' -----------------------------------------------------------------------------
' SOFTWARE LICENSE SECTION   
' -----------------------------------------------------------------------------
{{
┌────────────────────────────────────────────────────────────────────────────┐
│                     TERMS OF USE: MIT License                              │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy│
│of this software and associated documentation files (the "Software"), to    │
│deal in the Software without restriction, including without limitation the  │
│rights to use, copy, modify, merge, publish, distribute, sublicense, and/or │
│sell copies of the Software, and to permit persons to whom the Software is  │
│furnished to do so, subject to the following conditions:                    │
│                                                                            │
│The above copyright notice and this permission notice shall be included in  │
│all copies or substantial portions of the Software.                         │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  │
│IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    │
│FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE │
│AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     │
│FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS│
│IN THE SOFTWARE.                                                            │
└────────────────────────────────────────────────────────────────────────────┘
}}       
* TwilioX: Wrapper for the Twilio.com API
* Created 5/12/15 by Todd Landrum, todd@paladinpgm.com
* Project hosted on VFPX

* This is a very basic API wrapper for working with Twilio.com. It only does a few
* of the many, many API calls. 

* With thanks to:
*    Steve Bodnar - Who's Web API talk introduced me to Twilio
*    Toni Feltman - Who's Restful API talk introduced me to Curl
*    Eric Selje - Who's LibCurl with Freshbook provided good examples. 
*    Southwest Fox Conference - Where I learned of all of the above. 

* Methods
*    SendText: Send a text message


* A sample call:
*!*		SET PROCEDURE TO w:\vfp7com\prog\TwilioX

*!*		PUBLIC o 
*!*		o = NEWOBJECT("TwilioX")
*!*		o.cAccount = "YourAccountSID"		
*!*		o.cAuthToken = "YourAuthToken"	
*!*		o.cFrom = "YourTwilioNumber"		

*!*		IF !o.SendText("ToNumber", "Messsage")
*!*			?"Send", "Failed", o.cErrorMessage
*!*			return
*!*		ELSE
*!*			* Good Send
*!*		endif


* Makes use of:
*    cURL: http://curl.haxx.se/download.html 
*    LibCurl for VFP: http://www.ctl32.com/libcurl.asp 
*    Twilio API: https://www.twilio.com/docs/api/rest/sending-messages#post
*    Have to setup a Twilio account. Sample instructions for that are here:
*			http://mastervision.paladinpgm.com/help/hs2116.htm

* Project Includes
*    LibCurl.prg - From the LibCurl install
*    TwilioX.prg - This program

* Dependencies for distribution:
*    libcurl.dll, libcurl.h, libeay32.dll, libssl32.dll, vfp2c32.dll - All from LibCurl


DEFINE CLASS TwilioX AS Custom

cAccount = ""         && This needs to be set by user. 
cAuthToken = ""       && This needs to be set by user. 
cFrom = ""            && From phone number, this needs to be set by user. 

cCountryCode = "+1"   && Phone country code, see: http://www.allareacodes.com/international_dialing_codes.htm

cData = ""			&& Data returned by Twilio from the call
cErrorMessage = ""	&& Any returned error message
cParms = ""			&& The parms that were passed 
cURL = "https://api.twilio.com/2010-04-01/"	&& The URL to Stripe API

iResult = 0			&& Supposed to return 1 on a fail, 0 on success. 

oCurl = ""	&& libCurl object for making the calls. 

************************** 
PROCEDURE Init()

	IF ATC("LIBCURL.VCX", UPPER(SET("ClassLib"))) = 0
		SET CLASSLIB TO LibCurl addi
	ENDIF
	
	this.oCurl = NEWOBJECT("libCurl")
	
ENDPROC
************************** 
FUNCTION Destroy()

	this.oCurl = Null

ENDFUNC
************************** 
* RAS 12-May-2016, added country code and want to ensure some validation
*  is performed to protect developer from poorly formed values to pass
*  to Twilio. Not validating actual and valid country code.
FUNCTION cCountryCode_Assign(tuCountryCode)

LOCAL lcCountryCode

* Just in case developer passes numeric country code as numeric
IF VARTYPE(tuCountryCode) = "N"
   lcCountryCode = TRANSFORM(tuCountryCode)
ELSE
   lcCountryCode = ALLTRIM(tcCountryCode)
ENDIF 

IF LEFTC(lcCountryCode, 1) == "+"
   * Nothing to do
ELSE
   lcCountryCode = "+" + lcCountryCode   
ENDIF 

this.cCountryCode = lcCountryCode

ENDFUNC
************************** 
FUNCTION AddParm()
* Adds one parameter to a parameter string. Can be called multiple times then
* to build parameter string in prepartion for calling oCurl with a bunch
* of parameters. See Charge method for an example on this works. 
* Mostly an internal method, not something called in your program. 
PARAMETERS tName, tValue

	IF !EMPTY(this.cParms)
		this.cParms = this.cParms + "&"
	ENDIF
	
	this.cParms = this.cParms + tName + "="
	
	DO case
	
		CASE VARTYPE(tValue) = "N"
			this.cParms = this.cParms + TRANSFORM(tValue)
			
		OTHERWISE	&& String
			this.cParms = this.cParms + tValue
			
	ENDCASE
	
endfunc
************************** 
FUNCTION SendText()
* Parameters:
*	To: Phone number you are sending to
* 	Body: The body of the message to send

PARAMETERS tTo, tBody

	this.CurlReset()
	
	* Check the from number
	IF this.cCountryCode $ this.cFrom
		* Good
	ELSE 
		this.cFrom = this.cCountryCode + this.cFrom
	ENDIF
	
	* Pass all the parameters to Stripe
	this.AddParm("From", this.cFrom)
	this.AddParm("To", tTo)
	this.AddParm("Body", tBody)
	this.oCurl.curlOptCopyPostfields = this.cParms

	* Make the call
	this.CurlPerform("Accounts/" + this.cAccount + [/Messages])

	IF this.iResult = 0
		RETURN .t.
	ELSE 
		this.cErrorMessage = STREXTRACT(this.cData, "<Message>", "</Message>")
		RETURN .f.
	ENDIF 

ENDFUNC 
************************** 
FUNCTION CurlPerform

PARAMETERS tFunction

	this.oCurl.curlOptUrl = this.cURL + tFunction
	this.iResult = this.oCurl.curlEasyPerform()
	this.cData = this.oCurl._DataBuffer
	this.iResult = VAL(STREXTRACT(this.cData, "<Code>", "</Code>"))
	this.cParms = ""

ENDFUNC 
************************** 
FUNCTION CurlReset()
* Reset curl in preperation for another call. 

	this.oCurl.CurlEasyReset()

	* Parameters we'll need
	this.oCurl.curlOptUserPwd = this.cAccount + ":" + this.cAuthToken
	
	* EasyReset resets parameters, have to redo them. 	
	this.oCurl.curlOptPost = .T.
	this.oCurl.curlOptPostFieldsize=-1 && Let curl figure this out

	this.ocurl.CurlOptSslVerifyPeer = .f.
	this.ocurl.CurlOptSSLVerifyHost = 0
	this.ocurl.curloptport = 443
	
	this.iResult = 0
	this.cErrorMessage = ""
	this.cData = ""
	
ENDFUNC
************************** 


ENDDEFINE 
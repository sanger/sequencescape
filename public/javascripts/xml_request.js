	/**
	* Purpose:
	*   Creates a new HTTP request object
	*/	
	function getXmlHttpObject()
	{
       var httpRequest = new window.XMLHttpRequest();
       if (!httpRequest) {
           throw('Giving up - Cannot create an XMLHTTP object');
           return null;
       }
		return(httpRequest);
	}

	/**
	* Purpose:
	*   Simple synchronous HTTP request for an XML document
	*/	
   function xmlRequest(url,ssoToken) {

		var http = getXmlHttpObject();
		var mode = "GET";
		try {
   		http.open(mode,url,false);  	// Synchronous request
		} catch (e){
			consoleDump(e.toString() + url);
			return null;
		}
		if (ssoToken != undefined){
			http.setRequestHeader("Set-Cookie",ssoToken);			// SSO authentication cookie
		}
		http.setRequestHeader("Accept","text/xml");
   		//http.overrideMimeType("text/xml");
		http.send(null);         		// Locked until response returns
		//consoleDump(http.responseText);
		return(http.responseXML);
	}

function consoleDump(s)
{
}

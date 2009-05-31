/*
hack for xslt processors that do not respect disable-output-escaping="yes"
checks to see if output escaping has occcurred; if not, it does it
to-do: this doesn't check to see if the javascript options performed are possible given the web browser
*/
function fixescaping(items) {
	var newconent;
	for (var i=0; i<items.length; i++) {
		if (items[i].className == 'x-escape') {
			newcontent = items[i].textContent;
			if (newcontent && (newcontent.indexOf('&') != -1 || newcontent.indexOf('<') != -1)) { items[i].innerHTML = newcontent; }
			}
		}
	}
if (document.getElementById('encoding-test').innerHTML != '&amp;') {
	fixescaping(document.getElementsByTagName('div'));
	if (document.getElementById('nav')) { fixescaping(document.getElementById('nav').getElementsByTagName('a')); }
	}

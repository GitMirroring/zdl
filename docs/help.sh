#!/bin/bash -i
#
# ZigzagDownLoader (ZDL)
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published 
# by the Free Software Foundation; either version 3 of the License, 
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see http://www.gnu.org/licenses/. 
# 
# Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (author)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#


function usage {
    streaming="$(fold -w 80 -s $path_usr/streaming.txt)"
    hosting="$(fold -w 80 -s $path_usr/hosting.txt)"
    livestream="$(fold -w 80 -s $path_usr/livestream.txt)"
    generated="$(fold -w 80 -s $path_usr/generated.txt)"
    shortlinks="$(fold -w 80 -s $path_usr/shortlinks.txt)"
    programs="$(fold -w 80 -s $path_usr/programs.txt)"

    if [ "$language" == it_IT.UTF-8 ]
    then
        echo -en "ZigzagDownLoader (ZDL)

Uso (l'ordine degli argomenti non è importante):
  zdl [OPZIONI] [FILE_1 FILE_2 ...] [LINK_1 LINK_2 ...] [DIR]

         FILE_n                Nomi dei file da cui estrarre i LINK.
                               I file devono essere testuali
                               oppure container DLC o file TORRENT, 
                               questi ultimi contrassegnati rispettivamente 
                               dalle estensioni .dlc e .torrent
                               ($PROG processa comunque i LINK in memoria
                               nella DIR e quelli in input)

         LINK_n                URL dei file oppure delle pagine web 
                               dei servizi di hosting, streaming 
                               o di reindirizzamento (se omessi, 
                               $PROG processa quelli in memoria 
                               nella DIR e nei FILE). 
                               Per scaricare via IRC/XDCC, il link
                               deve avere la seguente forma (porta 
                               non necessaria se è 6667):
                                 irc://[HOST[:PORT]]/[CHAN]/msg [PRIVMSG]
                               
                               ZDL accetta anche i link di xWeasel 
                               (con protocollo xdcc://)

         DIR                   Directory di avvio di $PROG 
                               e di destinazione dei download 
                               (se omessa, è quella corrente)
  

OPZIONI
  Le opzioni brevi non seguite da valori possono essere contratte:
  '-ufmd' equivale a '-u -f -m -d'


  -h,  --help                  Help di ZigzagDownLoader ($PROG)

       --list-extensions       Elenco delle estensioni di $PROG 

       --aria2                 Scarica con Aria2
       --wget                  Scarica con Wget
       --axel                  Scarica con Axel

  -m [N], --max-downloads=[NUMERO] 
                               Numero massimo di download da effettuare
                               contemporaneamente: 
                                 0 = pausa
                                 >0 = limite download paralleli
                                 nessun numero = nessun limite
       
       --login	               Utilizza eventuali account registrati per i
                               servizi abilitati (configurare ${PROG})

  -u,  --update   	       Aggiorna $PROG
  -f,  --force                 Forza l'aggiornamento manuale di $PROG

       --clean  	       Cancella eventuali file temporanei dalla
	                       directory di destinazione, prima di effettuare
	         	       il download 

  -i,  --interactive           Avvia l'interfaccia interattiva di ZDL per i
	     	               download che hanno come destinazione la
			       directory attuale. I download gestiti possono
			       essere attivi o registrati nei file temporanei
			       della directory

  -d,  --daemon 	       Avvia ZDL in modalità \"demone\" (può essere
                               controllato attraverso l'interfaccia
                               interattiva) 

  -l,  --lite                  Avvia ZDL in modalità standard output \"lite\" 
                               (sono validi i comandi della modalità 
                               \"standard output\") 

       --open-relink=<LINK>    Processa i collegamenti fino all'ultimo URL 
                               raggiungibile a partire da LINK, poi apre tale URL 
                               usando il browser web configurato

       --out=<PROG|FILE>       Restituisce in output i nomi dei file 
                               dei download completati, in due modi alternativi:
                                 PROG: programma che può \"aprire\" il file 
                                       scaricato
                                 FILE: file testuale in cui sono registrati 
                                       i nomi dei file

       --live                  Permette di selezionare canali per il download
                               della diretta di alcune televisioni in \"live stream\"

       --mp3                   Convertono i file (anche da video in audio) 
       --flac                  in MP3 oppure in FLAC: dipende da FFMpeg/AVConv
                                
       --ip		       Scrive l'indirizzo IP attuale, prima di
                               effettuare altre operazioni

       --reconnect             Forza la riconnessione del modem al termine
                               di ogni download, utilizzando
                               uno script/comando/programma (configurare ${PROG})

  -r,  --resume                Recupera o riscarica file parzialmente scaricati.
                               Agisce in caso di omonimia fra file (leggi il manuale).
                               Può essere configurato come comportamento predefinito.

       --no-complete           Cancella i file temporanei dei download completati

       --no-stop               Avvio senza interruzioni: salta l'eventuale aggiornamento 
                               automatico (che richiede l'immissione della password) o la
                               richiesta di immettere nuovi link. L'input da tastiera
                               è comunque disponibile

       --external-application-button [HREF]
                               Per usare ${PROG} come gestore esterno di download
                               per Firefox, Opera, Chrome/Chromium.
                               L'opzione deve essere inserita nel campo 'Arguments'
                               delle preferenze dell'estensione External Application Button.
                               '[HREF]' non deve essere modificato.

Interfaccia grafica (GUI):
  -g,  --gui                   Avvia l'interfaccia grafica nella directory corrente o 
                               in quella eventualmente inserita fra gli argomenti, 
                               attivando automaticamente zdl --daemon come \"core\", 
                               se ancora non è stato attivato zdl

       --path-gui              Prima di avviare zdl, apre una finestra per la selezione 
                               della directory di destinazione, se non è indicata 
                               fra gli argomenti del comando (utile se \"zdl --gui\" 
                               è avviato da un'icona del desktop o da un'estensione 
                               del browser web, come \"External Application Button\")


Socket e interfacce utente:
  -s [porta], --socket[=porta]
                               Avvia il programma collegandolo a un socket. 
                               Se non indicata, la porta è quella predefinita.

  --web-ui
                               Interfaccia utente web. Avvia:
                               - il programma in modalità demone nella directory corrente o,
                                 eventualmente, in quella inserita come argomento, 
                               
                               - un socket alla porta predefinita o, se usata 
                                 da un'altra applicazione, alla prima porta libera 
                               
                               - il browser predefinito all'indirizzo dell'interfaccia utente. 


IRC/XDCC:
  -x,  --xdcc                  Avvia l'inserimento interattivo di tre dati:
                               1) l'host del server IRC (HOST)
                               2) il canale a cui connettersi (CHAN)
                               3) il messaggio privato (PRIVMSG) che contiene 
                                  il comando XDCC SEND

                               Il download via IRC/XDCC può essere affettuato, 
                               alternativamente e senza usare opzioni, inserendo le 
                               informazioni nel link, che deve avere la forma 
                               seguente (porta non necessaria se è 6667):
                                  irc://[HOST[:PORT]]/[CHAN]/msg [PRIVMSG]

  -X <keywords>, --xdcc-search=<keywords>
                               Utilizzando il motore di ricerca di https://www.xdcc.eu
                               avvia la ricerca di file disponibili per il download via XDCC.
                               Il risultato della ricerca è aperto da una GUI, per permettere
                               una selezione dei file da scaricare.
                               Lo stesso tipo di ricerca può essere effettuato
                               da --gui e --web-ui
                               <keywords> è la chiave di ricerca e deve essere racchiusa
                               fra virgolette singole o doppie


Torrent (Aria2):
  -T <FILE>, --torrent-file=<FILE>     File torrent per Aria2: 
                                       può non avere estensione .torrent

       --tcp-port=<NUM>        Porte TCP e UDP aperte: 
       --udp-port=<NUM>        verificare le impostazioni del router


Filtri:
       --scrape-url=<URL>      Estrae gli URL/link dalla pagina web indicata e
                               li accoda all'elenco registrato

       --scrape-url            Estrae gli URL (i link) dalle pagina web indicate 
                               come LINK

       --url=<REGEX>           Processa solo gli URL (i link) che corrispondono 
                               alla REGEX

       --no-url=<REGEX>        Non processa gli URL (i link) che corrispondono 
                               alla REGEX

       --file=<REGEX>          Scarica solo file il cui nome corrisponde alla REGEX

       --no-file=<REGEX>       Non scarica i file il cui nome corrisponde alla REGEX

       --no-rev                Non scarica i file con estensione '.rev'

       --no-sub                Non scarica i file il cui nome contiene le stringhe 
                               'Sub' o 'sub' (per file video sottotitolati)


Editor per i link (può essere usato in qualunque momento con Meta-e):
sostituisce l'interfaccia iniziale per l'immissione dei link

  -e,  --editor                Editor predefinito (si può configurare con 'zdl -c')

       --emacs, --emacs-nw     Emacs e la sua versione '-nw' (senza grafica)
       --jed                   piccolo editor in stile GNU Emacs
       --jupp                  Jupp
       --mcedit                Midnight Commander Editor
       --mg                    micro editor in stile GNU Emacs
       --nano                  Nano
       --vi, --vim             Vi e Vim
       --zile                  micro editor in stile GNU Emacs


Avvio con proxy:
       --proxy		       Avvia ZDL attivando un proxy
		               automaticamente (il tipo di proxy
		               predefinito è Transparent) 

       --proxy=<t|a|e>         Avvia ZDL attivando un proxy del tipo
		               definito dall'utente:
			    	 t = Transparent
			    	 a = Anonymous
			    	 e = Elite
			
       --proxy=<IP:PORTA>      Avvia ZDL attivando il proxy indicato
		               all'utente, per l'intera durata del
		               download (il proxy viene sostituito
			       automaticamente solo per i link dei
			       servizi abilitati che necessitano di
			       un nuovo indirizzo IP) 


Configurazione:
  -c,  --configure	       Interfaccia di configurazione di ZDL, 
			       permette anche di salvare eventuali
			       account dei servizi di hosting


Per scaricare lo stream incorporando ${PROG} in nuovi script, 
il modello generico dei parametri per le componenti aggiuntive (rispettare l'ordine): 
       --stream [PARAMETRI] [--noXterm]


SERVIZI
______ Video in streaming saltando il player del browser:
$streaming

______ File hosting:
$hosting

______ Live stream:
$livestream

______ Link generati dal web (anche dopo captcha):
$generated

______ Short links:
$shortlinks

______ Tutti i file scaricabili con i seguenti programmi:
$programs

______ Tutti i file scaricabili con le seguenti estensioni dei browser:
'Flashgot' e 'External Application Button' di Firefox/Iceweasel/Icecat/Chrome/Chromium, 
funzione 'M-x zdl' di Conkeror e script 'zdl-xterm' (XXXTerm/Xombrero e altri)


DOCUMENTAZIONE
  - ipertesto in formato info, consultabile con: 'info zdl'
  - ipertesto in formato html: http://nongnu.org/zdl
  - pagina di manuale in stile Unix: 'man zdl'


COPYING
  ZDL è rilasciato con licenza GPL (General Public Licence, v.3 e superiori). 


Per informazioni e per collaborare al progetto:
  - http://nongnu.org/zdl
  - https://savannah.nongnu.org/projects/zdl
  - https://joindiaspora.com/tags/zdl

Gianluca Zoni (zoninoz)
http://inventati.org/zoninoz
" | less

    else
        echo -ne "ZigzagDownLoader (ZDL)

Use (the order of the topics is not important):
  zdl [OPTIONS] [FILE_1 FILE_2 ...] [LINK_1 LINK_2 ...] [DIR]

         FILE_n                Names of the files from which to extract the LINKS.
                               The files must be textual
                               or DLC container or TORRENT file,
                               the latter marked respectively
                               from the extensions .dlc and .torrent
                               ($PROG still processes the LINKS in memory
                               in the DIR and those in input)

         LINK_n                URL of files or web pages
                               hosting, streaming services
                               or redirection (if omitted,
                               $PROG processes those in memory
                               in the DIR and in the FILE).
                               To download via IRC/XDCC, the link
                               must have the following form (port
                               not necessary if it is 6667):
                                 irc://[HOST[:PORT]]/[CHAN]/msg [PRIVMSG]

                               ZDL also accepts xWeasel links
                               (with protocol xdcc://)

         DIR                   $PROG startup directory
                               and destination for downloads
                               (if omitted, it is the current one)


OPTIONS
  Short options not followed by values can be contracted:
  '-ufmd' is equivalent to '-u -f -m -d'


  -h,  --help ZigzagDownLoader help ($PROG)

       --list-extensions       List of extensions of $ PROG

       --aria2                 Download with Aria2
       --wget                  Download with Wget
       --axel                  Download with Axel

  -m [N], --max-downloads = [NUMBER]
                               Maximum number of downloads to be made
                               simultaneously:
                                 0 = pause
                                 >0 = parallel download limit
                                 no number = no limit

       --login                 Use any registered accounts for
                               the enabled services (configure ${PROG})

  -u,  --update                Update $PROG
  -f,  --force                 Forces manual updating of $PROG

       --clean                 Delete any temporary files from
                               destination directory, before making
                               the download

  -i,  --interactive           Launch the interactive ZDL interface for
                               the downloads targeting
                               current directory. Managed downloads can
                               be active or registered in temporary files
                               of the directory

  -d,  --daemon                Start ZDL in \"daemon\" mode (can be
                               controlled through the interactive interface)

  -l,  --lite                  Start ZDL in \"lite\" standard output mode
                               (the \"standard output\" mode commands are valid)

       --open-relink=<LINK>    ZDL processes links up to the last URL reachable 
                               starting from LINK, then opens this URL using 
                               the configured web browser
                               
       --out=<PROG|FILE>       Returns the file names of
                               completed downloads, in two alternative ways:
                                 PROG: program that can open the file
                                       downloaded
                                 FILE: text file in which file names are registered
                                       
       --live                  Allows you to select channels for download
                               live broadcast of some televisions in live stream

       --mp3                   Convert files (even from video to audio)
       --flac                  in MP3 or FLAC: depends on FFMpeg/AVConv

       --ip                    Write the current IP address, before
                               perform other operations

       --reconnect             Forces the modem to reconnect on completion
                               of each download, using
                               a script/command/program (configure ${PROG})

  -r,  --resume                Recover or download partially downloaded files.
                               It acts in case of homonymy between files (read the manual).
                               It can be configured as the default behavior.

       --no-complete           Delete temporary files of completed downloads

       --no-stop               Start without interruption: skip any automatic 
                               update (which requires entry of the password) or
                               request to enter new links. Keyboard input
                               is still available

       --external-application-button [HREF]
                               To use ZDL as an external download manager
                               for Firefox, Opera, Chrome/Chromium.
                               The option must be entered in the 'Arguments' field
                               of the 'External Application Button' extension preferences.
                               '[HREF]' should not be changed.


Graphical user interface (GUI):
  -g,  --gui                   Start the graphical interface in the current directory or
                               in that eventually inserted between the arguments,
                               automatically activating 'zdl --daemon' as a core
                               if you have not yet activated zdl

       --path-gui              Before starting zdl, opens a selection window
                               of the destination directory, if it is not indicated
                               between the command arguments (useful if 'zdl --gui'
                               is started from a desktop icon or extension
                               web browser, such as 'External Application Button')


Sockets and user interfaces:
  -s [port], --socket[=port]
                               Start the program by connecting it to a socket.
                               If not indicated, the port is the default one.

  --web-ui
                               Web user interface. Start:
                               - the program in daemon mode in the current directory or,
                                 eventually, in the one inserted as an argument,

                               - a socket at the default port or, if used
                                 by another application, to the first free port

                               - the default browser at the user interface address.


IRC / XDCC:
  -x,  --xdcc                  Start the interactive insertion of three data:
                               1) the host of the IRC server (HOST)
                               2) the channel to connect to (CHAN)
                               3) the private message (PRIVMSG) that contains
                                  the XDCC SEND command

                               Download via IRC/XDCC can be done,
                               alternatively and without using options, by entering the
                               information in the link, which must have the
                               following form (port not necessary if it is 6667):
                                  irc://[HOST[:PORT]]/[CHAN]/msg [PRIVMSG]


  -X <keywords>, --xdcc-search=<keywords>
                               Using the https://www.xdcc.eu engine, start searching
                               for files available for download via XDCC.
                               The search result is opened by a GUI, to allow
                               a selection of files to download.
                               The same type of search can be performed
                               from --gui and --web-ui
                               <keywords> is the search key and must be enclosed
                               in single or double quotes


Torrent (Aria2):
  -T <FILE>, --torrent-file=<FILE>      Torrent files for Aria2:
                                        may not have a '.torrent' extension

       --tcp-port=<NUM>        Open TCP and UDP ports:
       --udp-port=<NUM>        check the router settings


filters:
       --scrape-url=<URL>      Extract URLs/links from the indicated web page 
                               and add them to the registered list

       --scrape-url            Extracts the URLs (links) from the indicated web pages
                               as LINK

       --url=<REGEX>           Process only the URLs (links) that match
                               to REGEX

       --no-url=<REGEX>        Does not process the URLs (links) that match
                               to REGEX

       --file=<REGEX>          Download only files whose name corresponds to the REGEX

       --no-file=<REGEX>       It does not download the files whose name corresponds to the REGEX

       --no-rev                Do not download files with '.rev' extension

       --no-sub                Does not download files whose name contains strings
                               'Sub' or 'sub' (for subtitled video files)


Link editor (can be used at any time with Meta-e):
replaces the initial interface for entering links

  -e,  --editor                Editor default (can be configured with 'zdl -c')

       --emacs, --emacs-nw     Emacs and its '-nw' version (without graphics)
       --jed                   small GNU Emacs style editor
       --jupp                  Jupp
       --mcedit                Midnight Commander Editor
       --mg                    micro editor in GNU Emacs style
       --nano                  Nano
       --vi, --vim             Vi and Vim
       --zile                  micro editor in GNU Emacs style


Start with proxy:
       --proxy                 Start ZDL by activating a proxy
                               automatically (the type of default proxy
                               is Transparent)

       --proxy=<t|a|e>         Start ZDL by activating a type proxy
                               user defined:
                                 t = Transparent
                                 a = Anonymous
                                 e = Elite

       --proxy=<IP:PORT>       Start ZDL by activating the indicated proxy
                               to the user, for the entire duration of the
                               download (the proxy is automatically replaced
                               only for links to enabled services that need
                               a new IP address)


Configuration:
  -c,  --configure             ZDL configuration interface,
                               also allows you to save any
                               hosting services account


To download the stream by embedding ${PROG} in new scripts,
the generic model of the parameters for the additional components (comply with the order):
       --stream [PARAMETERS] [--noXterm]


SERVICES
______ Streaming video skipping the browser player:
$streaming

______ File hosting:
$hosting

______ Live stream:
$livestream

______ Links generated by the web (even after captcha):
$generated

______ Short links:
$shortlinks

______ All files downloadable with the following programs:
$programs

______ All files downloadable with the following browser extensions:
'Flashgot' and 'External Application Button' for Firefox/Iceweasel/Icecat/Chrome/Chromium,
Conkeror 'M-x zdl' function and script 'zdl-xterm' (XXXTerm/Xombrero and others)


DOCUMENTATION
  - hypertext in info format, available with: 'info zdl'
  - hypertext in html format: http://nongnu.org/zdl
  - Unix-style manual page: 'man zdl'


COPYING
  ZDL is released under the GPL license (General Public License, v.3 and above).


For information and to collaborate on the project:
  - http://nongnu.org/zdl
  - https://savannah.nongnu.org/projects/zdl
  - https://joindiaspora.com/tags/zdl

Gianluca Zoni (zoninoz)
http://inventati.org/zoninoz
" | less

    fi
    
    echo
    cursor on
    exit 1
}

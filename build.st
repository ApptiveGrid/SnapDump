"Loads the SnapDump server into the image the Dockerfile prepared. The recipe is the one
that loads github:// dependencies on a Pharo 13 image in a build container; each step is
there for a failure it was found to prevent."

Iceberg enableMetacelloIntegration: false.
Deprecation raiseWarning: false.
EpMonitor current disable.

"GitHub answers a zipball request with a redirect whose content-security-policy header is
one line of about 9 KB, and Zinc refuses a line over 4 KB with ZnLineTooLong. The github://
loads go through Zinc, so the limit is raised before the first of them. The Zinc load below
replaces these methods with its own, which is why the limit is raised again after it."
ZnConstants class compile: 'maximumLineLength

   ^ 64 * 1024'.

ZnOptions class compile: 'maximumLineLength
   <znOption>

   ^ 64 * 1024'.
ZnOptions resetGlobalDefault.

"From a build container a download from GitHub now and then gets no data at all and runs
into the socket timeout, while the same download is there at once the next time. Waiting
longer does not help such a download, trying again does: up to three times, with a socket
timeout of a minute."
ZnNetworkingUtils defaultSocketStreamTimeout: 60.

MCGitBasedNetworkRepository class compile: 'downloadZipArchive: url to: outputFileName
	"tried up to three times (build.st): a download now and then gets no data at all and
	runs into the socket timeout, while the next one is there at once"

	| attempts |
	attempts := 0.
	[ outputFileName asFileReference ensureDelete.
	  ZnClient new
		url: url;
		downloadTo: outputFileName ]
		on: ConnectionTimedOut
		do: [ :error |
			(attempts := attempts + 1) < 3 ifFalse: [ error pass ].
			Transcript show: ''retrying '' , url asString; cr.
			error retry ].
	^ ZipArchive new readFrom: outputFileName asFileReference'.

"Zinc first and locked: the baseline of SnapDump names the same project, and a locked one is
not asked for again, so the load below cannot replace Zinc a second time."
[ Metacello new
	repository: 'github://svenvc/zinc/repository';
	baseline: 'ZincHTTPComponents';
	onConflictUseIncoming;
	ignoreImage;
	load: #('REST');
	lock ]
	on: MCMergeOrLoadWarning
	do: [ :ex | ex load ].

ZnConstants class compile: 'maximumLineLength

   ^ 64 * 1024'.

ZnOptions class compile: 'maximumLineLength
   <znOption>

   ^ 64 * 1024'.
ZnOptions resetGlobalDefault.

[ Metacello new
	repository: 'filetree:///opt/source';
	baseline: 'SnapDump';
	onConflict: [ :ex | ex useIncoming ];
	onWarningLog;
	load: #('server') ]
	on: MCMergeOrLoadWarning
	do: [ :ex | ex load ].

"the image is saved with the timeout of an HTTP request of the server, not of a download"
ZnOptions class compile: 'socketStreamTimeout
	"The timeout in seconds for network socket stream operations like connecting, reading and writing."
	<znOption>
	^ 30'.
ZnOptions resetGlobalDefault.

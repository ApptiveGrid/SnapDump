Class {
	#name : #SDHandler,
	#superclass : #SnapDump,
	#instVars : [
		'project',
		'version',
		'emergencyHandler',
		'propertiesProvider'
	],
	#category : #'SnapDump-Handler'
}

{ #category : #'as yet unclassified' }
SDHandler class >> fillExamples [
	| handler |
	handler := SDHandler new
		store: SnapDump current store.

1 to: 2 do: [:x| | snapshot |
	1 to: 2 do: [ :y |
		1 to: 2 do: [ :z |  
	handler 
		projectName: ('projectname', x asString) 
		versionString: '1.', y asString.
	snapshot := SDSnapshot dummyContextSnapshot.
	handler handleSnapshot: snapshot ] ] ]
]

{ #category : #accessing }
SDHandler class >> type [
	^ #handler
]

{ #category : #setup }
SDHandler >> applyConfiguration: aConfig [
	super applyConfiguration: aConfig.
	self 
		projectName:  aConfig project
		versionString: aConfig version

]

{ #category : #accessing }
SDHandler >> defaultEmergencyHandler [
	^ [ :emergency :exception | 
		"if we run inside a test case raise the error"
		CurrentExecutionEnvironment value isTest ifTrue: [ emergency pass ].

		Transcript show: 'Error ', emergency description asString, ' happened while report error ', exception description asString.
		nil ].
]

{ #category : #accessing }
SDHandler >> emergencyHandler [

	^ emergencyHandler ifNil: [ 
		emergencyHandler := self defaultEmergencyHandler ]
]

{ #category : #accessing }
SDHandler >> emergencyHandler: anObject [

	emergencyHandler := anObject
]

{ #category : #services }
SDHandler >> handleException: exception [
	
	store ifNil: [ 
		Transcript show: 'SnapDump store is not set up. Ignoring exception sends!!!'; cr.
		^ nil ].
	^ [ 
		Transcript show: 'SnapDump: exception to report: ', exception description asString; cr.
		self handleSnapshot: (self snapshotFor: exception) ]
		on: Error 
		do: [ :emergency | 
			"if an error occurrs while reporting an error we call the 
			emergeny handler with the original exception and "
			self emergencyHandler
				value: emergency 
				value: exception ]

]

{ #category : #services }
SDHandler >> handleSnapshot: snapshot [
	self store isSetUp
		ifTrue: [ Transcript show: 'SnapDump: store is set up'.
			self store
				storeSnapshot:
					(snapshot
						versionString: self version;
						projectName: self project;
						yourself) ]
		ifFalse: [ Transcript
				show: 'tried to store snapshot but store is not set up';
				cr ].
	^ snapshot
]

{ #category : #accessing }
SDHandler >> project [
	^ project ifNil: [ 'NoProject' ]
]

{ #category : #accessing }
SDHandler >> project: anObject [
	project := anObject
]

{ #category : #accessing }
SDHandler >> projectName: projectName versionString: versionString [
	self project: projectName.
	self version: versionString
]

{ #category : #accessing }
SDHandler >> propertiesProvider [
	^ propertiesProvider ifNil: [
		propertiesProvider := [ :exception | Dictionary new ] ]
]

{ #category : #accessing }
SDHandler >> propertiesProvider: aBlock [
	"aBlock takes the exception and answers a dictionary of properties for its
	snapshot. It runs in the process that signaled, so process local state like
	the current database is still there"
	propertiesProvider := aBlock
]

{ #category : #services }
SDHandler >> snapshotFor: exception [
	| snapshot |
	snapshot := exception asSnapshot.
	"a failing provider must not cost the report itself"
	[ snapshot properties addAll: (self propertiesProvider value: exception) ]
		on: Error
		do: [ :error | snapshot propertyAt: 'propertiesError' put: error description ].
	^ snapshot
]

{ #category : #accessing }
SDHandler >> version [
	^ version ifNil: [ 'noVersion' ]
]

{ #category : #accessing }
SDHandler >> version: anObject [
	version := anObject
]

pragma solidity ^0.5.8;
	pragma experimental ABIEncoderV2;
	

	contract ARSN_IPFS {
	

	

	////////////// INITIALIZE MAPPINGS AND ARRAYS
	

	      // mappings to hold data values and and corresponding arrays for their keys
	      mapping (bytes32 => uint[]) diagnoses; //key = diagnosis
	      mapping (bytes32 => uint[]) patientIDs; //key = patientID
	      mapping (string => uint[]) Gertzbein_grades; //key = Gertzbein_grade
	

	      mapping (uint => PatientDataStruct) database;
	      // counter to assign each entry a unique index
	      uint counter;
	      // array to hold the unique diagnosis-patientIDNumber-GertzbeinGrading entries
	      UniqueObservations[] uniqueObservationsArray;
	

	

	///////////////// DEFINE STRUCTS
	

	    // Struct format to return data from query function.
	    struct ObservationReturnStruct {
	        string diagnosis;
	        uint grade;
	        uint patientID;
	        uint screw_diameter;
	        string Gertzbein_grade;
	        bytes32 ipfsHash;
	        //uint totalCount;
	    }
	    // struct to hold the data in database
	    struct PatientDataStruct {
	        bytes32 diseaseField;
	        bytes32 gradeField;
	        bytes32 patientIDField;
	        bytes32 screw_diameterField;
	        string Gertzbein_gradeField;
	        bytes32 ipfsHashField;
	        uint index;
	        address whoAdded;
	    }
	    // struct to hold unique disease-patientID-GertzbeinGrading combinations
	    struct UniqueObservations {
	    	bytes32 diagnosis;
	    	bytes32 patientID;
	    	string Gertzbein_grade;
	    }
	    // struct to check which fields were queried
	    struct FieldQueries {
	        bool disease;
	        bool patientIDNumber;
	        bool GertzbeinGrading;
	    }
	

	

	//////////////////// INSERT and QUERY FUNCTIONS
	

	    //  Inserts observation. No return value.
	    function insertRecord (
	        string memory diagnosis,
	        uint grade,
	        uint patientID,
	        uint screw_diameter,
	        string memory Gertzbein_grade,
	        bytes32 ipfsHash
	    ) public {
	        bytes32 name = stringToBytes32(diagnosis);
	        bytes32 grading = stringToBytes32(intToString(grade));
	        bytes32 patientIDNumber = stringToBytes32(intToString(patientID));
	        bytes32 screw_diameter = stringToBytes32(intToString(screw_diameter));
	        bytes32 IPFS_hash = ipfsHash;
	        address who = msg.sender;
	

	        // check if the disease-patientIDNumber-GertzbeinGrading combo already exists in the database. If not, add it to the uniqueObservationsArray
	        if (observationExists(diagnosis, intToString(patientID), Gertzbein_grade) == false) {
	            uniqueObservationsArray.push(UniqueObservations(name, patientIDNumber, Gertzbein_grade));
	        }
	        // update the four mappings
	        diagnoses[name].push(counter);
	        patientIDs[patientIDNumber].push(counter);
	        Gertzbein_grades[Gertzbein_grade].push(counter);
	        database[counter] = PatientDataStruct(name, grading, patientIDNumber, screw_diameter, Gertzbein_grade, IPFS_hash, counter, who);
	        // update global counter/index
	        counter++;
	    }
	

	

	// Takes diagnosis, patientIDNumber, and GertzbeinGradingname as strings. Asterisk "*" fconsidered as wildcard. Returns array of ObservationReturnStruct Structs which match the query parameters.
	 function retrieveRecord(
	        string memory diagnosis,
	        string memory patientID,
	        string memory GertzbeinGrading
	    ) public view returns (ObservationReturnStruct[] memory) {
	        // initialize memory structs and variables
	        uint numFields;
	        FieldQueries memory queryInfo;
	        ObservationReturnStruct[] memory empty;
	        uint[] memory diseaseSearch;
	        uint[] memory patientIDSearch;
	        uint[] memory Gertzbein_gradeSearch;
	        uint[] memory indexSearch = new uint[](counter);
	        UniqueObservations[] memory uniqueSearch = new UniqueObservations[](uniqueObservationsArray.length);
	

	        // if database is empty, return empty array
	        if (counter == 0) {
	            return empty;
	        }
	        // count the number of fields used to search
	        if (compareStrings(diagnosis, "*") == false) { // if diagnosis field was not "*", increase numFields & mark diagnosis true in queryInfo struct
	            diseaseSearch = diagnoses[stringToBytes32(diagnosis)];
	            numFields++;
	            queryInfo.disease = true;
	        }
	        if (compareStrings(patientID, "*") == false) { // if patientID field was not "*", increase numFields & mark patientID true in queryInfo struct
	            patientIDSearch = patientIDs[stringToBytes32(patientID)];
	            numFields++;
	            queryInfo.patientIDNumber = true;
	        }
	        if (compareStrings(GertzbeinGrading, "*") == false) { // if GertzbeinGrading field was not "*", increase numFields & mark GertzbeinGrading true in queryInfo struct
	            Gertzbein_gradeSearch = Gertzbein_grades[GertzbeinGrading];
	            numFields++;
	            queryInfo.GertzbeinGrading = true;
	        }
	

	        uint matchCount; // num entries in the database that matched the query
	        uint uniqueCount; // num unique disease-patientIDNumber-GertzbeinGrading combos in the query results
	

	        if ((compareStrings(diagnosis, "*") == true) &&
	            (compareStrings(patientID, "*") == true) &&
	            (compareStrings(GertzbeinGrading, "*") == true)
	            ) {
	            matchCount = counter;
	            uniqueCount = uniqueObservationsArray.length;
	            uniqueSearch = uniqueObservationsArray;
	            for (uint i; i < counter; i++) {
	                indexSearch[i] = i;
	            }
	        } else {
	            uint min = counter;
	            uint which_one = 3;
	            if (diseaseSearch.length <= min && diseaseSearch.length != 0){
	                min = diseaseSearch.length;
	                which_one = 0;
	            }
	            if (patientIDSearch.length <= min && patientIDSearch.length != 0){
	                min = patientIDSearch.length;
	                which_one = 1;
	            }
	            if (Gertzbein_gradeSearch.length <= min && Gertzbein_gradeSearch.length != 0){
	                min = Gertzbein_gradeSearch.length;
	                which_one = 2;
	            }
	            if (diseaseSearch.length == patientIDSearch.length && patientIDSearch.length == Gertzbein_gradeSearch.length) {
	                min = diseaseSearch.length;
	                which_one = 0;
	            }
	

	            for (uint i; i < min; i++) {
	                uint found = 1;
	                //if shortest array is diseasesearch
	                if (which_one == 0) {
	                    if (queryInfo.patientIDNumber == true) {
	                        for (uint j; j < patientIDSearch.length; j++){
	                            if (diseaseSearch[i] == patientIDSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (queryInfo.GertzbeinGrading == true) {
	                        for (uint j; j < Gertzbein_gradeSearch.length; j++){
	                            if (diseaseSearch[i] == Gertzbein_gradeSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (found == numFields){
	                        indexSearch[matchCount] = diseaseSearch[i];
	                        matchCount++;
	                        PatientDataStruct memory addMe = database[diseaseSearch[i]];
	                        if (observationExistsUnique(addMe.diseaseField, addMe.patientIDField, addMe.Gertzbein_gradeField, uniqueSearch) == false) {
	                            uniqueSearch[uniqueCount] = UniqueObservations(addMe.diseaseField, addMe.patientIDField, addMe.Gertzbein_gradeField);
	                            uniqueCount++;
	                        }
	                    }
	                }
	                //if shortest array patientIDsearch
	                if (which_one == 1){
	                    if (queryInfo.disease == true) {
	                        for (uint j; j < diseaseSearch.length; j++){
	                            if (patientIDSearch[i] == diseaseSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (queryInfo.GertzbeinGrading == true) {
	                        for (uint j; j < Gertzbein_gradeSearch.length; j++){
	                            if (patientIDSearch[i] == Gertzbein_gradeSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (found == numFields){
	                        indexSearch[matchCount] = patientIDSearch[i];
	                        matchCount++;
	                        PatientDataStruct memory addMe = database[patientIDSearch[i]];
	                        if (observationExistsUnique(addMe.diseaseField, addMe.patientIDField, addMe.Gertzbein_gradeField, uniqueSearch) == false) {
	                            uniqueSearch[uniqueCount] = UniqueObservations(addMe.diseaseField, addMe.patientIDField, addMe.Gertzbein_gradeField);
	                            uniqueCount++;
	                        }
	                    }
	                }
	                //if shortest array is Gertzbein_gradesearch
	                if (which_one == 2){
	                    if (queryInfo.patientIDNumber == true) {
	                        for (uint j; j < patientIDSearch.length; j++){
	                            if (Gertzbein_gradeSearch[i] == patientIDSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (queryInfo.disease == true) {
	                        for (uint j; j < diseaseSearch.length; j++){
	                            if (Gertzbein_gradeSearch[i] == diseaseSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (found == numFields){
	                        indexSearch[matchCount] = Gertzbein_gradeSearch[i];
	                        matchCount++;
	                        PatientDataStruct memory addMe = database[Gertzbein_gradeSearch[i]];
	                        if (observationExistsUnique(addMe.diseaseField, addMe.patientIDField, addMe.Gertzbein_gradeField, uniqueSearch) == false) {
	                            uniqueSearch[uniqueCount] = UniqueObservations(addMe.diseaseField, addMe.patientIDField, addMe.Gertzbein_gradeField);
	                            uniqueCount++;
	                        }
	                    }
	                }
	            }
	        }
	

	        //trim arrays to increase looping efficiency
	        uint[] memory trimIndexSearch = new uint[](matchCount);
	        UniqueObservations[] memory trimUniqueSearch = new UniqueObservations[](uniqueCount);
	        for (uint i; i < matchCount; i++) {
	            trimIndexSearch[i] = indexSearch[i];
	        }
	        for (uint j; j < uniqueCount; j++) {
	            trimUniqueSearch[j] = uniqueSearch[j];
	        }
	

	        // build final struct from search results
	        ObservationReturnStruct[] memory matches = new ObservationReturnStruct[](uniqueCount); // final struct array
	        uint tally; // num entries for a given disease-patientIDNumber-GertzbeinGrading combo
	        for (uint a; a < trimUniqueSearch.length; a++){
	            uint[] memory sameThing = new uint[](counter);
	            tally = 0;
	            for (uint b; b < matchCount; b++) {
	                 // number of matches per unique combo
	                if ((trimUniqueSearch[a].diagnosis == database[trimIndexSearch[b]].diseaseField) &&
	                    (trimUniqueSearch[a].patientID == database[trimIndexSearch[b]].patientIDField) &&
	                    compareStrings(trimUniqueSearch[a].Gertzbein_grade, database[trimIndexSearch[b]].Gertzbein_gradeField)
	                    ) {
	                    sameThing[tally] = trimIndexSearch[b]; // add search result to sameThing if it matches uniqueSearch a
	                    tally++;
	                }
	            }
	

	            matches[a].diagnosis = bytes32toString(database[sameThing[0]].diseaseField);
	            matches[a].patientID = stringToInt(bytes32toString(database[sameThing[0]].patientIDField));
	            matches[a].screw_diameter = stringToInt(bytes32toString(database[sameThing[0]].screw_diameterField));
	            matches[a].Gertzbein_grade = database[sameThing[0]].Gertzbein_gradeField;
	            matches[a].ipfsHash = (database[sameThing[0]].ipfsHashField);
	            matches[a].grade = stringToInt(bytes32toString(database[sameThing[0]].gradeField));
	        }
	        return matches; // final struct array of diseaseGertzbeinGradingpatientID structs
	    }
	

	//////////////////// AUXILIARY UTILITIES
	

	// Checks if observation already exists and returns boolean value. If wild card is used, then true if any relation exists that passes the non-wildcard criteria.
	   function observationExists(
	        string memory diagnosis,
	        string memory patientID,
	        string memory GertzbeinGrading
	    ) public view returns (bool){
	         // initialize memory structs and variables
	        uint numFields;
	        uint[] memory diseaseSearch;
	        uint[] memory patientIDSearch;
	        uint[] memory Gertzbein_gradeSearch;
	

	        FieldQueries memory queryInfo;
	        // if database is empty, return empty array
	        if (counter == 0) {
	            return false;
	        }
	

	        // count the number of fields used to search
	        if (compareStrings(diagnosis, "*") == false) {
	            numFields++;
	            queryInfo.disease = true;
	            diseaseSearch = diagnoses[stringToBytes32(diagnosis)];
	        }
	        if (compareStrings(patientID, "*") == false) {
	            numFields++;
	            queryInfo.patientIDNumber = true;
	            patientIDSearch = patientIDs[stringToBytes32(patientID)];
	        }
	        if (compareStrings(GertzbeinGrading, "*") == false) {
	            numFields++;
	            queryInfo.GertzbeinGrading = true;
	            Gertzbein_gradeSearch = Gertzbein_grades[GertzbeinGrading];
	        }
	

	        if ((compareStrings(diagnosis, "*") == true) &&
	            (compareStrings(patientID, "*") == true) &&
	            (compareStrings(GertzbeinGrading, "*") == true)
	            ) {
	            return true;
	

	        } else {
	            uint min = counter;
	            uint which_one = 3;
	            if (diseaseSearch.length <= min && diseaseSearch.length != 0){
	                min = diseaseSearch.length;
	                which_one = 0;
	            }
	            if (patientIDSearch.length <= min && patientIDSearch.length != 0){
	                min = patientIDSearch.length;
	                which_one = 1;
	            }
	            if (Gertzbein_gradeSearch.length <= min && Gertzbein_gradeSearch.length != 0){
	                min = Gertzbein_gradeSearch.length;
	                which_one = 2;
	            }
	            if (diseaseSearch.length == patientIDSearch.length && patientIDSearch.length == Gertzbein_gradeSearch.length) {
	                min = diseaseSearch.length;
	                which_one = 0;
	            }
	            uint found;
	            for (uint i; i < min; i++) {
	                found = 1;
	                //if shortest array is diseasesearch
	                if (which_one == 0) {
	                    if (queryInfo.patientIDNumber == true) {
	                        for (uint j; j < patientIDSearch.length; j++){
	                            if (diseaseSearch[i] == patientIDSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (queryInfo.GertzbeinGrading == true) {
	                        for (uint j; j < Gertzbein_gradeSearch.length; j++){
	                            if (diseaseSearch[i] == Gertzbein_gradeSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (found == numFields) {
	                        break;
	                    }
	                }
	                //if shortest array patientIDsearch
	                if (which_one == 1){
	                    if (queryInfo.disease == true) {
	                        for (uint j; j < diseaseSearch.length; j++){
	                            if (patientIDSearch[i] == diseaseSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (queryInfo.GertzbeinGrading == true) {
	                        for (uint j; j < Gertzbein_gradeSearch.length; j++){
	                            if (patientIDSearch[i] == Gertzbein_gradeSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (found == numFields){
	                        break;
	                    }
	                }
	                //if shortest array is Gertzbein_gradesearch
	                if (which_one == 2){
	                    if (queryInfo.patientIDNumber == true) {
	                        for (uint j; j < patientIDSearch.length; j++){
	                            if (Gertzbein_gradeSearch[i] == patientIDSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (queryInfo.disease == true) {
	                        for (uint j; j < diseaseSearch.length; j++){
	                            if (Gertzbein_gradeSearch[i] == diseaseSearch[j]){
	                                found++;
	                                break;
	                            }
	                        }
	                    }
	                    if (found == numFields){
	                        break;
	                    }
	                }
	            }
	            if (found == numFields){
	                return true;
	            }
	            else{
	                return false;
	            }
	        }
	    }
	

	// Checks if a disease-patientIDNumber-GertzbeinGrading combination already exists in a UniqueObservations[] array and returns boolean
	    function observationExistsUnique (
	        bytes32 diagnosis,
	        bytes32 patientID,
	        string memory GertzbeinGrading,
	        UniqueObservations[] memory array) internal pure returns (bool){
	        if (array.length == 0) {
	            return false;
	        }
	        uint searcher;
	        for (uint j; j < array.length; j++) {
	            if (array[j].diagnosis == diagnosis && array[j].patientID == patientID && compareStrings(array[j].Gertzbein_grade, GertzbeinGrading) == true) {
	                searcher++;
	                break;
	            }
	        }
	        if (searcher == 1){
	            return true;
	        } else {
	            return false;
	        }
	    }
	

	// Converts uints to strings. from https://github.com/willitscale/solidity-util/blob/master/lib/Integers.sol
	    function intToString(uint _base) internal pure returns (string memory) {
	        bytes memory _tmp = new bytes(32);
	        uint i;
	        for(i; _base > 0; i++) {
	            _tmp[i] = byte(uint8((_base % 10) + 48));
	            _base /= 10;
	        }
	        bytes memory _real = new bytes(i--);
	        for(uint j; j < _real.length; j++) {
	            _real[j] = _tmp[i--];
	        }
	        return string(_real);
	    }
	

	// Converts string to a uint from https://github.com/willitscale/solidity-util/blob/master/lib/Integers.sol
	    function stringToInt(string memory _value) internal pure returns (uint _ret) {
	        bytes memory _bytesValue = bytes(_value);
	        uint j = 1;
	        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
	            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
	            _ret += (uint8(_bytesValue[i]) - 48)*j;
	            j*=10;
	        }
	    }
	

	// Compares two strings
	    function compareStrings(
	    	string memory a,
	    	string memory b
	    	) internal pure returns (bool){
	        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
	    }
	

	// Converts string to bytes32
	  	function stringToBytes32(string memory _string) internal pure returns (bytes32) {
	   		bytes32 _stringBytes;
	    	assembly {
	      	_stringBytes := mload(add(_string, 32))
	    	}
	    	return _stringBytes;
	  	}
	

	// Converts bytes32 to string data type
		function bytes32toString(bytes32 _data) internal pure returns (string memory) {
	    	bytes memory _bytesContainer = new bytes(32);
	    	uint256 _charCount;
	    	for (uint256 _bytesCounter; _bytesCounter < 32; _bytesCounter++) {
	      		bytes1 _char = bytes1(bytes32(uint256(_data) * 2 ** (8 * _bytesCounter)));
	      		if (_char != 0) {
	        		_bytesContainer[_charCount] = _char;
	       			_charCount++;
	      		}
	    	}
	    	bytes memory _bytesContainerTrimmed = new bytes(_charCount);
	    	for (uint256 _charCounter; _charCounter < _charCount; _charCounter++) {
	      		_bytesContainerTrimmed[_charCounter] = _bytesContainer[_charCounter];
	    	}
	    	return string(_bytesContainerTrimmed);
	 	}
	

	} // END OF CONTRACT


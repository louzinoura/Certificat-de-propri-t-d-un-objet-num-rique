// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CertificateRegistry {
    // Structure pour stocker les informations du certificat
    struct Certificate {
        address owner;
        uint256 timestamp;
        bool exists;
    }

    // Mapping pour stocker hash => Certificate
    mapping(string => Certificate) public certificates;

    // Mapping pour stocker les certificats par propriétaire
    mapping(address => string[]) public ownerCertificates;
    // Liste globale des hashes
    string[] public allHashes;

    // Événements pour les logs
    event CertificateRegistered(string indexed hash, address indexed owner, uint256 timestamp);
    event CertificateTransferred(string indexed hash, address indexed from, address indexed to, uint256 timestamp);

    // Modificateur pour vérifier que le certificat existe
    modifier certificateMustExist(string memory hash) {
        require(certificates[hash].exists, "Ce certificat n'existe pas");
        _;
    }

    // Modificateur pour vérifier que l'appelant est le propriétaire
    modifier onlyOwner(string memory hash) {
        require(certificates[hash].owner == msg.sender, "Vous n'etes pas le proprietaire de ce certificat");
        _;
    }

    /**
     * @dev Enregistre un nouveau certificat
     * @param hash Le hash du fichier à certifier
     */
    function registerCertificate(string memory hash) public {
        require(!certificates[hash].exists, "Ce certificat existe deja");
        require(bytes(hash).length > 0, "Le hash ne peut pas etre vide");

        // Créer le certificat
        certificates[hash] = Certificate({
            owner: msg.sender,
            timestamp: block.timestamp,
            exists: true
        });

        // Ajouter à la liste des certificats du propriétaire
        ownerCertificates[msg.sender].push(hash);

        // Émettre l'événement
        emit CertificateRegistered(hash, msg.sender, block.timestamp);
        // Ajouter à la liste globale
        allHashes.push(hash);

    }

    /**
     * @dev Récupère le propriétaire d'un certificat
     * @param hash Le hash du certificat
     * @return owner L'adresse du propriétaire
     * @return timestamp Le timestamp d'enregistrement
     */
    function getCertificateOwner(string memory hash) public view certificateMustExist(hash) returns (address owner, uint256 timestamp) {
        Certificate memory cert = certificates[hash];
        return (cert.owner, cert.timestamp);
    }

    /**
     * @dev Vérifie si un certificat existe
     * @param hash Le hash du certificat
     * @return exists True si le certificat existe
     */
    function certificateExists(string memory hash) public view returns (bool exists) {
        return certificates[hash].exists;
    }

    /**
     * @dev Transfère un certificat à une nouvelle adresse
     * @param hash Le hash du certificat à transférer
     * @param newOwner La nouvelle adresse propriétaire
     */
    function transferCertificate(string memory hash, address newOwner) public certificateMustExist(hash) onlyOwner(hash) {
        require(newOwner != address(0), "L'adresse du nouveau proprietaire ne peut pas etre nulle");
        require(newOwner != msg.sender, "Vous ne pouvez pas transferer a vous-meme");

        address oldOwner = certificates[hash].owner;

        // Mettre à jour le propriétaire
        certificates[hash].owner = newOwner;
        certificates[hash].timestamp = block.timestamp;

        // Retirer le hash de la liste de l'ancien propriétaire
        _removeCertificateFromOwner(oldOwner, hash);

        // Ajouter le hash à la liste du nouveau propriétaire
        ownerCertificates[newOwner].push(hash);

        // Émettre l'événement de transfert
        emit CertificateTransferred(hash, oldOwner, newOwner, block.timestamp);
    }

    /**
     * @dev Récupère tous les certificats d'un propriétaire
     * @param owner L'adresse du propriétaire
     * @return hashes La liste des hashes des certificats
     */
    function getOwnerCertificates(address owner) public view returns (string[] memory hashes) {
        return ownerCertificates[owner];
    }

    /**
     * @dev Fonction interne pour retirer un certificat de la liste d'un propriétaire
     * @param owner L'adresse du propriétaire
     * @param hash Le hash à retirer
     */
    function _removeCertificateFromOwner(address owner, string memory hash) internal {
        string[] storage certs = ownerCertificates[owner];
        for (uint i = 0; i < certs.length; i++) {
            if (keccak256(abi.encodePacked(certs[i])) == keccak256(abi.encodePacked(hash))) {
                // Remplacer par le dernier élément et supprimer
                certs[i] = certs[certs.length - 1];
                certs.pop();
                break;
            }
        }
    }

    /**
     * @dev Récupère le nombre total de certificats enregistrés par un propriétaire
     * @param owner L'adresse du propriétaire
     * @return count Le nombre de certificats
     */
    function getCertificateCount(address owner) public view returns (uint256 count) {
        return ownerCertificates[owner].length;
    }
    function getAllCertificates() public view returns (string[] memory, address[] memory) {
    uint256 count = 0;
    for (uint256 i = 0; i < allHashes.length; i++) {
        if (certificates[allHashes[i]].exists) {
            count++;
        }
    }

    string[] memory validHashes = new string[](count);
    address[] memory owners = new address[](count);
    uint256 index = 0;

    for (uint256 i = 0; i < allHashes.length; i++) {
        if (certificates[allHashes[i]].exists) {
            validHashes[index] = allHashes[i];
            owners[index] = certificates[allHashes[i]].owner;
            index++;
        }
    }

    return (validHashes, owners);
}

}
 
const { ethers } = require("hardhat");
const { formatEther } = require("ethers");

async function main() {
  console.log("🚀 Déploiement du contrat CertificateRegistry...");

  // Récupérer le deployer
  const [deployer] = await ethers.getSigners();
  console.log("👤 Déployeur:", deployer.address);

  // Récupérer solde
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("💰 Solde du déployeur:", formatEther(balance), "ETH");

  // Préparer le contrat
  const CertificateRegistry = await ethers.getContractFactory("CertificateRegistry");
  console.log("📦 Déploiement en cours...");

  // Déployer
  const certificateRegistry = await CertificateRegistry.deploy();

  // Attendre la transaction de déploiement
  await certificateRegistry.deploymentTransaction().wait();

  // Afficher adresse et hash
  console.log("✅ Contrat déployé à l'adresse:", certificateRegistry.target);
  console.log("🔗 Hash de la transaction:", certificateRegistry.deploymentTransaction().hash);

  // Test rapide de la fonction d'enregistrement (optionnel)
  const testHash = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
  try {
    console.log("📝 Enregistrement d'un certificat test...");
    const tx = await certificateRegistry.registerCertificate(testHash);
    await tx.wait();
    console.log("✅ Certificat enregistré.");

    const exists = await certificateRegistry.certificateExists(testHash);
    console.log("🔍 Certificat existe ? ", exists);

    if (exists) {
      const [owner, timestamp] = await certificateRegistry.getCertificateOwner(testHash);
      console.log("👤 Propriétaire:", owner);
      console.log("⏰ Timestamp:", timestamp.toString());
    }

    const count = await certificateRegistry.getCertificateCount(deployer.address);
    console.log("📊 Nombre de certificats du déployeur:", count.toString());

  } catch (error) {
    console.error("❌ Erreur lors du test:", error);
  }

  console.log("🎉 Déploiement terminé !");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Erreur lors du déploiement :", error);
    process.exit(1);
  });

# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/claranet/argocd" {
  version     = "5.6.0-claranet0"
  constraints = "5.6.0-claranet0"
  hashes = [
    "h1:c/KW0ATrt26GbnBdScmBUFkwCHvJDIgAi+TE9Sgu8EI=",
    "zh:00088e1a9586ebbee7ce9307607f0df4763c6f746bad69df7ffdb2d371d3ab7e",
    "zh:04ac3c5ccf470d72710e71ca974550c1c105928261170038ab0ee199b1ec535d",
    "zh:04b651f51089911a8018b6329db07b8724daa2fb31c9fdb9a22d2486d60d0cfa",
    "zh:24d08533f9bf2e0bba6f517f762c3e4ae3f43a8652e81c4c97175604e8c3acbc",
    "zh:8875e950e4ff61ebb7de6965775652d5ceded201bc700312914ce802d7d3ae26",
    "zh:95f46120c4e19aee120c348b365afa631d83d29aeaa677f5c5e1652a3a1aa60a",
    "zh:a2c76559c126fa8fcf7466e9fb0ff3043545588b50506667689e8fa5a705a7e1",
    "zh:b8979a9180580f6d40ca445503bbcd178852db14e64f885f0d06a8c23632c0c2",
    "zh:df7c2aae009582fb62a2a1520a51b82baed46a13a8f8d5444f4a0c470fb645ee",
  ]
}

provider "registry.terraform.io/gavinbunney/kubectl" {
  version     = "1.19.0"
  constraints = "~> 1.14"
  hashes = [
    "h1:quymfa/OKEfWI5JXFEwGbUY2aAy0vet3rA9JWJam+3k=",
    "zh:1dec8766336ac5b00b3d8f62e3fff6390f5f60699c9299920fc9861a76f00c71",
    "zh:43f101b56b58d7fead6a511728b4e09f7c41dc2e3963f59cf1c146c4767c6cb7",
    "zh:4c4fbaa44f60e722f25cc05ee11dfaec282893c5c0ffa27bc88c382dbfbaa35c",
    "zh:51dd23238b7b677b8a1abbfcc7deec53ffa5ec79e58e3b54d6be334d3d01bc0e",
    "zh:5afc2ebc75b9d708730dbabdc8f94dd559d7f2fc5a31c5101358bd8d016916ba",
    "zh:6be6e72d4663776390a82a37e34f7359f726d0120df622f4a2b46619338a168e",
    "zh:72642d5fcf1e3febb6e5d4ae7b592bb9ff3cb220af041dbda893588e4bf30c0c",
    "zh:9b12af85486a96aedd8d7984b0ff811a4b42e3d88dad1a3fb4c0b580d04fa425",
    "zh:a1da03e3239867b35812ee031a1060fed6e8d8e458e2eaca48b5dd51b35f56f7",
    "zh:b98b6a6728fe277fcd133bdfa7237bd733eae233f09653523f14460f608f8ba2",
    "zh:bb8b071d0437f4767695c6158a3cb70df9f52e377c67019971d888b99147511f",
    "zh:dc89ce4b63bfef708ec29c17e85ad0232a1794336dc54dd88c3ba0b77e764f71",
    "zh:dd7dd18f1f8218c6cd19592288fde32dccc743cde05b9feeb2883f37c2ff4b4e",
    "zh:ec4bd5ab3872dedb39fe528319b4bba609306e12ee90971495f109e142d66310",
    "zh:f610ead42f724c82f5463e0e71fa735a11ffb6101880665d93f48b4a67b9ad82",
  ]
}

provider "registry.terraform.io/grafana/grafana" {
  version     = "2.19.4"
  constraints = "~> 2.0"
  hashes = [
    "h1:XjYARXNAS1YMgABhI5J3RknJbHvh/DjlVOcywc5I5w4=",
    "zh:10e1db6012433e84592cee299e7014deda1d9772f86f0f6f635e9d46543ebf25",
    "zh:2ef424112ff8b6fbd6ea918b3d1498af6bcbd5407b8adc862ad892b1ff3f7047",
    "zh:34697e3abbef0b01b883792983bcf0f9e55c131ce3afa167f76b8712384fbc50",
    "zh:4961c3de106e3b78cfb5cfc01946d17e062de274cacd60365f020a92c86a98f9",
    "zh:4eca84134b1ce5deb018246a87635677afce64689a72fef9a10b37b4d09cf47f",
    "zh:84568baf9deaa220c02e4b1b6797f1cb09547340baa07a0c1dbc53725275fd6e",
    "zh:956baf9dc58d4e6bdcc1148fc30b1a7ce0cf251e01d8c4e1c0249226be550d94",
    "zh:ad185a8c63c99f0408f4e6f3174c2854817143c59fd15f91771048e4ad91f6e5",
    "zh:c5a92a4089f21278cc214051895ad51b62e8420df1c310ade752f79c1379167d",
    "zh:da8b458d27434d775f482751a11a167a39fe9ba6c293e085116201def3d68437",
    "zh:de2d4f5c12799ee65f478ca7a8f90d48e0944b19b7918da841e167f175627278",
    "zh:e1cb92c84cbe42a8f2a54c2af70da4d85a131c7e5d82ac389451d2619f492a58",
    "zh:e836db1d0d1fa1c9618c3c0fec254c954d36cd0d9d11d39e74b3cdfdfaed053c",
    "zh:f0c7ae3fbcd2651348f1d8ec455f61eae59fd8a06cf97778b53c7b91bd0b981b",
  ]
}

provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.82.2"
  constraints = ">= 4.33.0, >= 5.61.0, ~> 5.82.2"
  hashes = [
    "h1:ce6Dw2y4PpuqAPtnQ0dO270dRTmwEARqnfffrE1VYJ8=",
    "zh:0262fc96012fb7e173e1b7beadd46dfc25b1dc7eaef95b90e936fc454724f1c8",
    "zh:397413613d27f4f54d16efcbf4f0a43c059bd8d827fe34287522ae182a992f9b",
    "zh:436c0c5d56e1da4f0a4c13129e12a0b519d12ab116aed52029b183f9806866f3",
    "zh:4d942d173a2553d8d532a333a0482a090f4e82a2238acf135578f163b6e68470",
    "zh:624aebc549bfbce06cc2ecfd8631932eb874ac7c10eb8466ce5b9a2fbdfdc724",
    "zh:9b12af85486a96aedd8d7984b0ff811a4b42e3d88dad1a3fb4c0b580d04fa425",
    "zh:9e632dee2dfdf01b371cca7854b1ec63ceefa75790e619b0642b34d5514c6733",
    "zh:a07567acb115b60a3df8f6048d12735b9b3bcf85ec92a62f77852e13d5a3c096",
    "zh:ab7002df1a1be6432ac0eb1b9f6f0dd3db90973cd5b1b0b33d2dae54553dfbd7",
    "zh:bc1ff65e2016b018b3e84db7249b2cd0433cb5c81dc81f9f6158f2197d6b9fde",
    "zh:bcad84b1d767f87af6e1ba3dc97fdb8f2ad5de9224f192f1412b09aba798c0a8",
    "zh:cf917dceaa0f9d55d9ff181b5dcc4d1e10af21b6671811b315ae2a6eda866a2a",
    "zh:d8e90ecfb3216f3cc13ccde5a16da64307abb6e22453aed2ac3067bbf689313b",
    "zh:d9054e0e40705df729682ad34c20db8695d57f182c65963abd151c6aba1ab0d3",
    "zh:ecf3a4f3c57eb7e89f71b8559e2a71e4cdf94eea0118ec4f2cb37e4f4d71a069",
  ]
}

provider "registry.terraform.io/hashicorp/cloudinit" {
  version     = "2.3.5"
  constraints = ">= 2.0.0"
  hashes = [
    "h1:Sf1Lt21oTADbzsnlU38ylpkl8YXP0Beznjcy5F/Yx64=",
    "zh:17c20574de8eb925b0091c9b6a4d859e9d6e399cd890b44cfbc028f4f312ac7a",
    "zh:348664d9a900f7baf7b091cf94d657e4c968b240d31d9e162086724e6afc19d5",
    "zh:5a876a468ffabff0299f8348e719cb704daf81a4867f8c6892f3c3c4add2c755",
    "zh:6ef97ee4c8c6a69a3d36746ba5c857cf4f4d78f32aa3d0e1ce68f2ece6a5dba5",
    "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
    "zh:8283e5a785e3c518a440f6ac6e7cc4fc07fe266bf34974246f4e2ef05762feda",
    "zh:a44eb5077950168b571b7eb65491246c00f45409110f0f172cc3a7605f19dba9",
    "zh:aa0806cbff72b49c1b389c0b8e6904586e5259c08dabb7cb5040418568146530",
    "zh:bec4613c3beaad9a7be7ca99cdb2852073f782355b272892e6ee97a22856aec1",
    "zh:d7fe368577b6c8d1ae44c751ed42246754c10305c7f001cc0109833e95aa107d",
    "zh:df2409fc6a364b1f0a0f8a9cd8a86e61e80307996979ce3790243c4ce88f2915",
    "zh:ed3c263396ff1f4d29639cc43339b655235acf4d06296a7c120a80e4e0fd6409",
  ]
}

provider "registry.terraform.io/hashicorp/null" {
  version     = "3.2.3"
  constraints = ">= 3.0.0"
  hashes = [
    "h1:I0Um8UkrMUb81Fxq/dxbr3HLP2cecTH2WMJiwKSrwQY=",
    "zh:22d062e5278d872fe7aed834f5577ba0a5afe34a3bdac2b81f828d8d3e6706d2",
    "zh:23dead00493ad863729495dc212fd6c29b8293e707b055ce5ba21ee453ce552d",
    "zh:28299accf21763ca1ca144d8f660688d7c2ad0b105b7202554ca60b02a3856d3",
    "zh:55c9e8a9ac25a7652df8c51a8a9a422bd67d784061b1de2dc9fe6c3cb4e77f2f",
    "zh:756586535d11698a216291c06b9ed8a5cc6a4ec43eee1ee09ecd5c6a9e297ac1",
    "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
    "zh:9d5eea62fdb587eeb96a8c4d782459f4e6b73baeece4d04b4a40e44faaee9301",
    "zh:a6355f596a3fb8fc85c2fb054ab14e722991533f87f928e7169a486462c74670",
    "zh:b5a65a789cff4ada58a5baffc76cb9767dc26ec6b45c00d2ec8b1b027f6db4ed",
    "zh:db5ab669cf11d0e9f81dc380a6fdfcac437aea3d69109c7aef1a5426639d2d65",
    "zh:de655d251c470197bcbb5ac45d289595295acb8f829f6c781d4a75c8c8b7c7dd",
    "zh:f5c68199f2e6076bce92a12230434782bf768103a427e9bb9abee99b116af7b5",
  ]
}

provider "registry.terraform.io/hashicorp/time" {
  version     = "0.12.1"
  constraints = ">= 0.9.0"
  hashes = [
    "h1:JzYsPugN8Fb7C4NlfLoFu7BBPuRVT2/fCOdCaxshveI=",
    "zh:090023137df8effe8804e81c65f636dadf8f9d35b79c3afff282d39367ba44b2",
    "zh:26f1e458358ba55f6558613f1427dcfa6ae2be5119b722d0b3adb27cd001efea",
    "zh:272ccc73a03384b72b964918c7afeb22c2e6be22460d92b150aaf28f29a7d511",
    "zh:438b8c74f5ed62fe921bd1078abe628a6675e44912933100ea4fa26863e340e9",
    "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
    "zh:85c8bd8eefc4afc33445de2ee7fbf33a7807bc34eb3734b8eefa4e98e4cddf38",
    "zh:98bbe309c9ff5b2352de6a047e0ec6c7e3764b4ed3dfd370839c4be2fbfff869",
    "zh:9c7bf8c56da1b124e0e2f3210a1915e778bab2be924481af684695b52672891e",
    "zh:d2200f7f6ab8ecb8373cda796b864ad4867f5c255cff9d3b032f666e4c78f625",
    "zh:d8c7926feaddfdc08d5ebb41b03445166df8c125417b28d64712dccd9feef136",
    "zh:e2412a192fc340c61b373d6c20c9d805d7d3dee6c720c34db23c2a8ff0abd71b",
    "zh:e6ac6bba391afe728a099df344dbd6481425b06d61697522017b8f7a59957d44",
  ]
}

provider "registry.terraform.io/hashicorp/tls" {
  version     = "4.0.6"
  constraints = ">= 3.0.0"
  hashes = [
    "h1:n3M50qfWfRSpQV9Pwcvuse03pEizqrmYEryxKky4so4=",
    "zh:10de0d8af02f2e578101688fd334da3849f56ea91b0d9bd5b1f7a243417fdda8",
    "zh:37fc01f8b2bc9d5b055dc3e78bfd1beb7c42cfb776a4c81106e19c8911366297",
    "zh:4578ca03d1dd0b7f572d96bd03f744be24c726bfd282173d54b100fd221608bb",
    "zh:6c475491d1250050765a91a493ef330adc24689e8837a0f07da5a0e1269e11c1",
    "zh:81bde94d53cdababa5b376bbc6947668be4c45ab655de7aa2e8e4736dfd52509",
    "zh:abdce260840b7b050c4e401d4f75c7a199fafe58a8b213947a258f75ac18b3e8",
    "zh:b754cebfc5184873840f16a642a7c9ef78c34dc246a8ae29e056c79939963c7a",
    "zh:c928b66086078f9917aef0eec15982f2e337914c5c4dbc31dd4741403db7eb18",
    "zh:cded27bee5f24de6f2ee0cfd1df46a7f88e84aaffc2ecbf3ff7094160f193d50",
    "zh:d65eb3867e8f69aaf1b8bb53bd637c99c6b649ba3db16ded50fa9a01076d1a27",
    "zh:ecb0c8b528c7a619fa71852bb3fb5c151d47576c5aab2bf3af4db52588722eeb",
    "zh:f569b65999264a9416862bca5cd2a6177d94ccb0424f3a4ef424428912b9cb3c",
  ]
}

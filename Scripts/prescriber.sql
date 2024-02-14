--ALL TABLES HERE
SELECT * FROM cbsa
SELECT * FROM drug
SELECT * FROM fips_county
SELECT * FROM overdose_deaths
SELECT * FROM population
SELECT * FROM prescriber
SELECT * FROM prescription
SELECT * FROM zip_fips

--1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT prescription.npi, SUM(prescription.total_claim_count) AS total_claims
FROM prescription
GROUP BY prescription.npi
ORDER BY total_claims DESC
LIMIT 3;
--ANSWER: npi:1881634483      total_claims:99707

--1b.Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT prescription.npi, SUM(prescription.total_claim_count) AS total_claims, 
	   nppes_provider_first_name AS first_name, nppes_provider_last_org_name AS last_name,
	   prescriber.specialty_description
FROM prescription
INNER JOIN prescriber
USING(npi)
GROUP BY prescription.npi, first_name, last_name,prescriber.specialty_description
ORDER BY total_claims DESC;
--ANSWER: ^^

--2a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT p1.specialty_description, SUM(p2.total_claim_count) AS total_claims
FROM prescriber AS p1
INNER JOIN prescription AS p2
USING(npi)
GROUP BY p1.specialty_description
ORDER BY total_claims DESC;
--ANSWER: Family Practice with 9752347

--2b. Which specialty had the most total number of claims for opioids?
SELECT p1.specialty_description, SUM(p2.total_claim_count) AS total_claims ,opioid_drug_flag
FROM prescriber AS p1
INNER JOIN prescription AS p2
ON p1.npi = p2.npi
INNER JOIN drug
ON p2.drug_name = drug.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY opioid_drug_flag, p1.specialty_description
ORDER BY total_claims DESC;
--ANSWER: Nurse Practitioner

--3a. Which drug (generic_name) had the highest total drug cost?
SELECT drug.generic_name, SUM(prescription.total_drug_cost) AS drug_cost
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY drug_cost DESC
--ANSWER: Insulin gargine, hum.rec.anlog

--3b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT drug.generic_name, ROUND(SUM(prescription.total_drug_cost) / SUM(prescription.total_day_supply),2) AS drug_cost_per_day
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY drug_cost_per_day DESC
--ANSWER: C1 ESTERASE INHIBITOR Cost of 3495.22 per day 

--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 
SELECT drug.drug_name, 
	  CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
	  WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	  ELSE 'neither' END AS drug_type 
FROM drug;
--ANSWER: ^^

--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT  
    CASE 
	  WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
	  WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	  ELSE 'neither' END AS drug_type, SUM(prescription.total_drug_cost) AS money
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug.opioid_drug_flag, drug.antibiotic_drug_flag
ORDER BY money DESC;
--ANSWER: opioid has a higher total cost

--5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%'
--ANSWER: 56

--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsa.cbsaname, cbsa, SUM(population.population) AS total_population
FROM cbsa
INNER JOIN population
ON cbsa.fipscounty = population.fipscounty
GROUP BY cbsa.cbsaname, cbsa
ORDER BY cbsa;
--ANSWER: 








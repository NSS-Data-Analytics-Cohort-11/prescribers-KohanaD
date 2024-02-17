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

--2d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
WITH claims AS
	(SELECT
		pr.specialty_description,
		SUM(rx.total_claim_count) AS total_claims
	FROM prescriber AS pr
	INNER JOIN prescription AS rx
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	GROUP BY pr.specialty_description),
-- second CTE for total opioid claims
opioid AS
	(SELECT
		pr.specialty_description,
		SUM(rx.total_claim_count) AS total_opioid
	FROM prescriber AS pr
	INNER JOIN prescription AS rx
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	WHERE drug.opioid_drug_flag ='Y'
	GROUP BY pr.specialty_description)
--main query
SELECT
	claims.specialty_description,
	ROUND((opioid.total_opioid / claims.total_claims * 100),2) AS perc_opioid
FROM claims
INNER JOIN opioid
USING(specialty_description);
--ANSWER: ^^ Thank you matt

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
ORDER BY total_population DESC;
--ANSWER: 34980: Highest, 34100: Smallest

--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT fips_county.county, population.population
FROM population
INNER JOIN fips_county
ON population.fipscounty = fips_county.fipscounty
LEFT JOIN cbsa
ON cbsa.fipscounty = fips_county.fipscounty
WHERE cbsa.cbsa IS NULL
GROUP BY fips_county.county, population.population
ORDER BY population.population DESC;
--ANSWER: SEVIER county with 95523 population

--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000;
--ANSWER: ^^

--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT prescription.drug_name, prescription.total_claim_count,
	CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'Opioid'
	ELSE 'Not Opioid' END AS opioid_drug
FROM prescription
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE prescription.total_claim_count > 3000
GROUP BY  prescription.drug_name, prescription.total_claim_count,drug.opioid_drug_flag
--ANSWER: Only 2 are opioid

--6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT prescription.drug_name, 
	   prescription.total_claim_count,
	   prescriber.nppes_provider_first_name AS first_name, 
	   prescriber.nppes_provider_last_org_name AS last_name,
	CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'Opioid'
	ELSE 'Not Opioid' END AS opioid_drug
FROM prescription
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
INNER JOIN prescriber
ON prescription.npi = prescriber.npi
WHERE prescription.total_claim_count > 3000
GROUP BY  prescription.drug_name, 
          prescription.total_claim_count,
		  drug.opioid_drug_flag,
		  prescriber.nppes_provider_last_org_name,
		  prescriber.nppes_provider_first_name;
--ANSWER: ^^

--7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT prescriber.npi, drug.drug_name
FROM prescriber
CROSS JOIN drug
WHERE prescriber.specialty_description = 'Pain Management'
	AND prescriber.nppes_provider_city = 'NASHVILLE'
	AND drug.opioid_drug_flag = 'Y'
--ANSWER: ^^

--7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT prescriber.npi, 
	   drug.drug_name, 
	   (SELECT
	   SUM(prescription.total_claim_count) 
	   FROM prescription
	   WHERE prescriber.npi = prescription.npi
	   AND prescription.drug_name = drug.drug_name ) AS total_claims 
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
using (npi)
	WHERE prescriber.specialty_description ilike 'Pain Management'
	AND prescriber.nppes_provider_city ilike 'NASHVILLE'
	AND drug.opioid_drug_flag = 'Y'
GROUP BY drug.drug_name, prescriber.npi
ORDER BY total_claims ASC
--ANSWER: ^^

--7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.	
SELECT prescriber.npi, 
	   drug.drug_name, 
	   (SELECT(COALESCE(SUM(prescription.total_claim_count),0))
	   FROM prescription
	   WHERE prescription.npi = prescriber.npi
	   AND prescription.drug_name = drug.drug_name) AS total_claims 
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
ON drug.drug_name = prescription.drug_name
	WHERE prescriber.specialty_description ilike 'Pain Management'
	AND prescriber.nppes_provider_city ilike 'NASHVILLE'
	AND drug.opioid_drug_flag = 'Y'
GROUP BY drug.drug_name, prescriber.npi
ORDER BY total_claims DESC
--ANSWER: ^^






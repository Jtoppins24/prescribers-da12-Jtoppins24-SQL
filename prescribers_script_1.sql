-- ## Prescribers Database

-- For this exericse, you'll be working with a database derived from the 
--[Medicare Part D Prescriber Public Use File]
--(https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). 
--More information about the data is contained in the Methodology PDF file. 
-- See also the included entity-relationship diagram.

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)?
--Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count) AS total_claims
	FROM prescription 
	GROUP BY npi
	ORDER BY total_claims DESC
	LIMIT 1;

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  
-- specialty_description, and the total number of claims.

SELECT 
	DISTINCT(prescriber.npi) AS provider, 
	SUM(prescription.total_claim_count) AS total_claims,
	prescriber.nppes_provider_first_name, 
	prescriber.nppes_provider_last_org_name, 
	specialty_description
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE prescription.total_claim_count IS NOT NULL
GROUP BY 
	npi,
	prescriber.nppes_provider_first_name, 
	prescriber.nppes_provider_last_org_name, 
	specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)? -- Family Practice 

SELECT prescriber.specialty_description AS specialty, 	SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE prescription.total_claim_count IS NOT NULL
GROUP BY specialty
ORDER BY total_claims DESC
LIMIT 1;

--Inner join better here by taking out the NULLS
SELECT prescriber.specialty_description AS specialty, 	SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription
USING(npi)
GROUP BY specialty
ORDER BY total_claims DESC
LIMIT 1;

--     b. Which specialty had the most total number of claims for opioids?

SELECT 
	prescriber.specialty_description AS specialty, 
	SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
JOIN drug
USING(drug_name)
WHERE prescription.total_claim_count IS NOT NULL
	AND drug.opioid_drug_flag = 'Y'
GROUP BY specialty
ORDER BY total_claims DESC;


--     c. **Challenge Question:** 
--Are there any specialties that appear in the prescriber table that have no associated 
--prescriptions in the prescription table? 
-- ^^ looking for records in the prescriber table that do NOT Have records in the prescription table 
-- Go back and try this with an EXCEPT 

--option #1
SELECT prescriber.specialty_description, COUNT(prescription.drug_name) AS num_prescriptions
FROM prescriber
LEFT JOIN prescription
USING(npi)
GROUP BY prescriber.specialty_description
HAVING COUNT(prescription.drug_name) = 0
;

--option #2 using except
SELECT prescriber.specialty_description
	FROM prescriber
	LEFT JOIN prescription
	USING(npi)
EXCEPT
SELECT prescriber.specialty_description
	FROM prescription
	LEFT JOIN prescriber
	USING(npi);

--option #3 using a subquery
SELECT DISTINCT specialty_description
FROM prescriber
WHERE specialty_description NOT IN
	(SELECT prescriber.specialty_description
	FROM prescription
	JOIN prescriber
	ON prescription.npi = prescriber.npi)
ORDER BY 1
	
--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
--For each specialty, report the percentage of total claims by that specialty which are for opioids. 
--Which specialties have a high percentage of opioids?

--Rob's example (look again)
SELECT
	specialty_description,
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) as opioid_claims,
	SUM(total_claim_count) AS total_claims,
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) * 100.0 /  SUM(total_claim_count) AS opioid_percentage
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
GROUP BY specialty_description
ORDER BY opioid_percentage DESC;

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT SUM(prescription.total_drug_cost)::money AS drug_cost, drug.generic_name
FROM prescription
JOIN drug
USING(drug_name)
GROUP BY drug.generic_name
ORDER BY drug_cost DESC
LIMIT 1;

--     b. Which drug (generic_name) has the hightest total cost per day (prescription.total_day_supply)? 

SELECT (SUM(prescription.total_drug_cost) / SUM(prescription.total_day_supply)) AS drug_cost_per_day, drug.generic_name
FROM prescription
JOIN drug
USING(drug_name)
GROUP BY drug.generic_name
ORDER BY drug_cost_per_day DESC
LIMIT 1; 

--**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT ROUND(SUM(prescription.total_drug_cost) / SUM(prescription.total_day_supply), 2) AS drug_cost_per_day, drug.generic_name
FROM prescription
JOIN drug
USING(drug_name)
GROUP BY drug.generic_name
ORDER BY drug_cost_per_day DESC
LIMIT 1; 

-- 4. 
--     a. For each drug in the drug table, 
--return the drug name and then a column named 'drug_type' which says 'opioid' for drugs 
--which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
--and says 'neither' for all other drugs. 
--**Hint:** You may want to use a CASE expression for this. 
--See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT drug_name, 
	(CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag ='Y' THEN 'antibiotic'
	ELSE 'neither'
	END)
	AS drug_type
FROM drug;

--test
SELECT drug_name, antibiotic_drug_flag
FROM drug
WHERE drug_name = 'AMIKACIN SULFATE';


--     b. Building off of the query you wrote for part a, 
--determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
--Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	(CASE 
	WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN drug.antibiotic_drug_flag ='Y' THEN 'antibiotic'
	ELSE 'neither'
	END)
	AS drug_type,
	SUM(prescription.total_drug_cost)::MONEY AS drug_cost
FROM drug
JOIN prescription
USING(drug_name)
GROUP BY drug_type
ORDER BY drug_cost DESC;

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(*)
FROM cbsa
WHERE cbsaname LIKE '%TN';

SELECT*
FROM cbsa;

--     b. Which cbsa has the largest combined population? (Nashville)
--Which has the smallest? (Morristown)
--Report the CBSA name and total population.
--Note to self: population table only shows TN 

SELECT cbsa.cbsaname, SUM(population.population) AS total_population
FROM cbsa
JOIN population
USING(fipscounty)
GROUP BY cbsa.cbsaname
ORDER BY total_population DESC;

--^^ inner join shows only 42 matching records... feel like this isn't showing me the full picture 

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

-- LOL this antijoin is wrong 
SELECT population.population, population.fipscounty
FROM population
WHERE fipscounty NOT IN 
	(SELECT fipscounty
	FROM cbsa)
ORDER BY population.population DESC;

-- redid 
SELECT county, population
FROM fips_county
LEFT JOIN population
USING(fipscounty)
LEFT JOIN cbsa
USING(fipscounty)
WHERE cbsa.cbsa IS NULL
	and population IS NOT NULL
ORDER BY population DESC
LIMIT 1;

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug.drug_name, 
	prescription.total_claim_count,
	(CASE 
	WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'neither'
	END)
	AS drug_type
FROM prescription
LEFT JOIN drug
USING(drug_name)
WHERE total_claim_count >= 3000;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT drug.drug_name, 
	prescription.total_claim_count,
	(CASE 
	WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'neither'
	END)
	AS drug_type,
	prescriber.nppes_provider_last_org_name,
	prescriber.nppes_provider_first_name
FROM prescription
LEFT JOIN drug
USING(drug_name)
LEFT JOIN prescriber
USING(npi)
WHERE total_claim_count >= 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
--and the number of claims they had for each opioid. 
--**Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists 
--(prescriber.specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
--where the drug is an opioid (opiod_drug_flag = 'Y'). 
-- ALL opioid drugs that an npi / provider COULD prescribe who works in Pain Management in NASHVILLE
-- **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT prescriber.npi, drug.drug_name
FROM prescriber
CROSS JOIN drug
WHERE prescriber.specialty_description = 'Pain Management'
AND prescriber.nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. 
--Be sure to include all combinations, whether or not the prescriber had any claims. 
--You should report the npi, the drug name, and the number of claims (total_claim_count).
--^^ join on 2 keys the second time to get more specific results (match both of these before returning), ie. bc the npi/providers could prescribe multiple diff drugs
--^^ if the row count goes up after a left join, that means there are duplicates 
-- ^^ returning nulls bc the prescriber didn't prescribe that drug
-- ^^ associating total_claims with BOTH the npi and drug_name 
--^^ double check things in the OG table

SELECT prescriber.npi, drug.drug_name, prescription.total_claim_count AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE prescriber.specialty_description = 'Pain Management'
AND prescriber.nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';


--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT prescriber.npi, drug.drug_name, COALESCE(prescription.total_claim_count, 0) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE prescriber.specialty_description = 'Pain Management'
AND prescriber.nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

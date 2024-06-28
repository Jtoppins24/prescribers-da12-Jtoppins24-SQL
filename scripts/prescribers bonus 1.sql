-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

-- option #1
SELECT COUNT(*)
	FROM
(SELECT npi
	FROM prescriber
	EXCEPT
SELECT npi
	FROM prescription)
	AS not_in_prescription;

-- option #2
SELECT COUNT(prescriber.npi)
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE prescription.npi IS NULL;

-- 2.
--     a. Find the top five drugs (drug.generic_name) [in terms of claims] prescribed by prescribers (prescriber.npi) with the specialty of Family Practice.
-- need a prescription join to get there

SELECT drug.generic_name, SUM(prescription.total_claim_count) as total_claims
FROM drug
JOIN prescription
USING(drug_name)
JOIN prescriber 
USING(npi)
WHERE prescriber.specialty_description = 'Family Practice'
GROUP BY drug.generic_name
ORDER BY total_claims DESC
	LIMIT 5;

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT drug.generic_name, SUM(prescription.total_claim_count) as total_claims
FROM drug
JOIN prescription
USING(drug_name)
JOIN prescriber 
USING(npi)
WHERE prescriber.specialty_description = 'Cardiology'
GROUP BY drug.generic_name
ORDER BY total_claims DESC
	LIMIT 5;

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
--Combine what you did for parts a and b into a single query to answer this question.

SELECT*
FROM
(SELECT drug.generic_name, SUM(prescription.total_claim_count) as total_claims_FP
FROM drug
JOIN prescription
USING(drug_name)
JOIN prescriber 
USING(npi)
WHERE prescriber.specialty_description = 'Family Practice'
GROUP BY drug.generic_name
ORDER BY total_claims_FP DESC
	LIMIT 5)
JOIN
(SELECT drug.generic_name, SUM(prescription.total_claim_count) as total_claims_Card
FROM drug
JOIN prescription
USING(drug_name)
JOIN prescriber 
USING(npi)
WHERE prescriber.specialty_description = 'Cardiology'
GROUP BY drug.generic_name
ORDER BY total_claims_Card DESC
	LIMIT 5)
USING(generic_name);

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) 
--across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT drug.generic_name, SUM(prescription.total_claim_count) as total_claims, prescriber.npi AS npi, prescriber.nppes_provider_city AS city
FROM drug
JOIN prescription
USING(drug_name)
JOIN prescriber 
USING(npi)
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
GROUP BY drug.generic_name, prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;
    
--     b. Now, report the same for Memphis.

SELECT drug.generic_name, SUM(prescription.total_claim_count) as total_claims, prescriber.npi AS npi, prescriber.nppes_provider_city AS city
FROM drug
JOIN prescription
USING(drug_name)
JOIN prescriber 
USING(npi)
WHERE prescriber.nppes_provider_city = 'MEMPHIS'
GROUP BY drug.generic_name, prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT drug.generic_name, SUM(prescription.total_claim_count) as total_claims, prescriber.npi AS npi, prescriber.nppes_provider_city AS city
FROM drug
JOIN prescription
USING(drug_name)
JOIN prescriber 
USING(npi)
WHERE prescriber.nppes_provider_city IN ('NASHVILLE','MEMPHIS','KNOXVILLE','CHATTANOOGA')
GROUP BY drug.generic_name, prescriber.npi, prescriber.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

-- 5.
--     a. Write a query that finds the total population of Tennessee.
    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

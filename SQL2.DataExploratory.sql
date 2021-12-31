--Housing Data Exploratory Analysis.

--Data preview
Select *
From PortfolioSQL.dbo.TennesseeHousing

--1. Housing value and price overview
--Average value break down by Proper City
Select PropertySplitCity, Avg(LandValue) lvalue,Avg(BuildingValue) bvalue,Avg(TotalValue) tvalue
From PortfolioSQL.dbo.TennesseeHousing
Group by PropertySplitCity
Order by tvalue desc
	--! Notice that Nolensville, Franklin and Bellevue has abnormal data: Avg BuildingValue = 0, which means they contain missing data points. We will exclude then these cities from the rest of the analysis.
	--! So the top 3 cities has highest house (total) value are Brentwood, Nashville and Mount Juliet.

--Compare to sale price
Select PropertySplitCity, Avg(SalePrice) aprice
From PortfolioSQL.dbo.TennesseeHousing
Group by PropertySplitCity
Order by aprice desc
	--! Nashville and Brentwood has an accurate price as they remain in top 3, while in Mount Juliet, buildings price are relatively low.
		--	Verification:
		Select PropertySplitCity, Avg(SalePrice/TotalValue) apriceacurate
		From PortfolioSQL.dbo.TennesseeHousing
		Group by PropertySplitCity
		Order by apriceacurate desc
		--!Buildings price are booming in Nashville (4.69 times of value), while it's close to real value in Mount Juliet. 
		--!In overall, price are higher than building total value which reflect that's the value measure method isn't accurate.

--Average on building's details
Select PropertySplitCity, Avg(Acreage) aacreage,Avg(Bedrooms) abed,Avg(FullBath) afullb, Avg(HalfBath) ahalfb
From PortfolioSQL.dbo.TennesseeHousing
Group by PropertySplitCity
Order by aacreage desc
	--! 3 cities with highest acreage are: Mount Juliet, Whites Creek and Brentwood. 
	--! While most cities have an average of 3 bedrooms per building, Mount Juliet and Brentwood are exceptional with an average of 3.5
	--!	We expect that house value are high in Brentwood and Mount Juliet due to its high acreage, while in Nashville it's inverse, the value/price per acre is high in this city.
		--  Verification:
		Select PropertySplitCity, Avg(TotalValue/acreage) valueperacreage
		From PortfolioSQL.dbo.TennesseeHousing	
		Group by PropertySplitCity
		Order by valueperacreage desc
		--As prediction, Nashville hold the highest value per acreage.

-- 2. Investment on real estate
-- We suppose that, when the OwnerAddress is different from PropertyAddress, that house is more likely an investment on real estate.
	--Testing method 
	Select	PropertySplitCity,
				Case 
					When OwnerSplitAddress is null or PropertySplitAddress is null then null
					When PropertySplitAddress = OwnerSplitAddress Then Cast (1 as bit) Else Cast (0 as bit)
				End as Investment
	From PortfolioSQL.dbo.TennesseeHousing
	-- Create temp table to visualize investment rate
	Select *
	Into PortfolioSQL.dbo.#investment_table
	From PortfolioSQL.dbo.TennesseeHousing

	Alter table PortfolioSQL.dbo.#investment_table
	Add Investment float
	Update PortfolioSQL.dbo.#investment_table
		Set	
		Investment =Case 
						When OwnerSplitAddress is null or PropertySplitAddress is null Then null --Avoiding null
						When Replace(OwnerSplitAddress, ' ', '') = Replace(PropertySplitAddress,' ', '') Then 0 Else 1 --Replace to avoid difference come from double space error
					End

--Querry result
Select PropertySplitCity, Avg(Investment) ainv
From PortfolioSQL.dbo.#investment_table
Group by PropertySplitCity
Order by ainv desc
--!Whites Creek has highest building investment rate with 8.3%, followed by Brentwood with 3.9%. 
--!Other cities has investment rate around or lower than 1% ( which is considerably low). This result might be inaccurate due to high number of data missing points.

--3. More on SoldAsVacant, break down on City
--Create temporary table for counting SoldAsVacant
Create table #SAV_Details(PropertySplitCity varchar(100),CountY float ,CountN float)
Insert into #SAV_Details
Select PropertySplitCity,
		Count (case when (SoldAsVacant)='Yes' then 1 end) as CountY,
		Count (case when (SoldAsVacant)='No' then 1 end) as CountN
From PortfolioSQL.dbo.TennesseeHousing
Group by PropertySplitCity
--Calculating SAV rate
Select PropertySplitCity, CountY/(CountY+CountN) as SAV_Rate
From #SAV_Details
Order by SAV_Rate desc
--!Mount Juliet has the highest SAV rate,with a record of 28%, followed by 4 cities Goodlettsville, Antioch, Nolensville and WhitesCreek with a SAV rate goes around 17%

---END OF DATA EXPLORATORY ANALYSIS---

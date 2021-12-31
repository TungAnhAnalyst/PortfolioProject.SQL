ke--Housing Data Cleaning.

--Data Preview
Select *
From PortfolioSQL.dbo.TennesseeHousingOriginal
--The dataset contain information about price, value, acreage and number of bedrooms and bathrooms from houses in Tennessee state, US

--Make a copy of the original table to work on
Select *
Into PortfolioSQL.dbo.TennesseeHousing
From PortfolioSQL.dbo.TennesseeHousingOriginal

-- PropertyAddress: Cleaning
--Checking null values in PropertyAddress column
Select *
From PortfolioSQL.dbo.TennesseeHousing
Where PropertyAddress is null
	--Recheck the database
	Select *	
	From PortfolioSQL.dbo.TennesseeHousing
	Order by ParcelID
		-- Notice that same ParcelID provide same PropertyAddress, so we should fill the null value in PropertyAddress by using ParcelID column
			-- Create column to update null value
			Select t1.ParcelID,t1.PropertyAddress,t2.ParcelID,t2.PropertyAddress, Coalesce(t1.PropertyAddress,t2.PropertyAddress)
			From PortfolioSQL.dbo.TennesseeHousing t1
			Join PortfolioSQL.dbo.TennesseeHousing t2
			On t1.ParcelID=t2.ParcelID
			And t1.[UniqueID ]<>t2.[UniqueID ]
			Where t1.PropertyAddress is null
			-- Update null values
			Update t1
			Set PropertyAddress = Coalesce(t1.PropertyAddress,t2.PropertyAddress)
			From PortfolioSQL.dbo.TennesseeHousing t1
			Join PortfolioSQL.dbo.TennesseeHousing t2
			On t1.ParcelID=t2.ParcelID
			And t1.[UniqueID ]<>t2.[UniqueID ]
			Where t1.PropertyAddress is null
--

-- SaleDate: Date Standardisation
Select SaleDate
From PortfolioSQL.dbo.TennesseeHousing
-- Time might be unecessary, so we drop it from the database
Alter table PortfolioSQL.dbo.TennesseeHousing
Alter column [SaleDate] Date
--

--YearBuilt: Transform to BuildingAge
--First we check data type of YearBuilt column
Exec sp_help TennesseeHousing
--YearBuilt is float type, we use normal substraction to calculate BuildingAge
	--Testing method
	Select YearBuilt, year(getdate())-YearBuilt as BuildingAge
	From TennesseeHousing

	--Store data in new column
	Alter table PortfolioSQL.dbo.TennesseeHousing
	Add BuildingAge float

	Update PortfolioSQL.dbo.TennesseeHousing
	Set 
	BuildingAge = year(getdate())-YearBuilt
--

--Address: Columns seperation
	--1. PropertyAddress
	--Create new columns
	Alter table PortfolioSQL.dbo.TennesseeHousing
	Add PropertySplitAddress Nvarchar(255),
		PropertySplitCity Nvarchar (255);
	--Update new columns to the database
	Update PortfolioSQL.dbo.TennesseeHousing
	Set 
	PropertySplitAddress = Parsename(Replace(PropertyAddress,',','.'),2),
    PropertySplitCity = Parsename(Replace(PropertyAddress,',','.'),1);
	
	--2.OwnerAddress
	--Creating new columns
	Alter table PortfolioSQL.dbo.TennesseeHousing
	Add OwnerSplitAddress Nvarchar(255),
		OwnerSplitCity Nvarchar(255),
		OwnerSplitState Nvarchar(255);
	--Update data using Parsename
	Update PortfolioSQL.dbo.TennesseeHousing
	Set 
	OwnerSplitAddress = Parsename(Replace(OwnerAddress,',','.'),3),
    OwnerSplitCity= Parsename(Replace(OwnerAddress,',','.'),2),
	OwnerSplitState = Parsename(Replace(OwnerAddress,',','.'),1);
--

--Sold As Vacant: Synchronize different inputs
-- Checking unsynchronized data
Select distinct SoldAsVacant
From PortfolioSQL.dbo.TennesseeHousing
-- We notice that we have 4 different values for only 2 main values (Yes/No)
--Testing method
Select distinct Replace(Replace(SoldAsVacant,'Y','Yes'),'N','No')
From PortfolioSQL.dbo.TennesseeHousing
Where SoldAsVacant = 'Y' or SoldAsVacant = 'N'
--Apply to database
Update TennesseeHousing
	Set
	SoldAsVacant = Replace(Replace(SoldAsVacant,'Y','Yes'),'N','No')
	From PortfolioSQL.dbo.TennesseeHousing
	Where SoldAsVacant = 'Y' or SoldAsVacant = 'N'
--

--Removal of Duplicate data
With DuplicateCheckCTE 
As(
Select *,
	ROW_NUMBER() over (
	Partition by	ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					Order by UniqueID
						) row_num
From PortfolioSQL.dbo.TennesseeHousing
	)
Delete
From DuplicateCheckCTE
Where row_num>1

--Drop unused Address columns
Alter table PortfolioSQL.dbo.TennesseeHousing
Drop Column PropertyAddress,OwnerAddress

--Updated database overview
Select *
From PortfolioSQL.dbo.TennesseeHousing
Order by [UniqueID ]

---END OF CLEANING PROCESS---


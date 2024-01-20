/** Question 2:
Games with multiple consoles:
a. How many games have been released with 3 or more Platforms? 
b. In which year were the highest number of Genres at their peak ? Please find
the Year & The Genres **/


/** Answer 2.a: **/

SELECT COUNT(*) AS Num_Games_On_3_Or_More_Platforms
FROM
-->>tbl
	(SELECT 
	 Name
	,COUNT(name) AS Count_Games
	FROM video_games
	GROUP BY 
	Name) tbl
WHERE Count_Games >=3

/** Answer 2.b: **/

WITH Peak_Genres_Per_Year_CTE AS (

SELECT 
 Year_of_Release
,SUM(is_Peak) AS Num_Of_Peak_Genres 
FROM
-->>tbl3
	(SELECT 
	 Year_of_Release
	,Genre
	,IIF(Sum_Of_Units_Sold=Top_Unit_Sold_Per_Genre,1,0) AS Is_Peak
	 FROM
	 -->>tbl2
		(SELECT 
		 Year_of_Release
		,Genre
		,Sum_Of_Units_Sold
		,MAX(Sum_Of_Units_Sold) OVER (PARTITION BY Genre) AS Top_Unit_Sold_Per_Genre
		FROM
		-->>tbl
			(SELECT 
			 Year_of_Release
			,Genre
			,SUM(Global_Sales) AS Sum_Of_Units_Sold
			FROM video_games
			WHERE Genre IS NOT NULL AND Year_of_Release IS NOT NULL
			GROUP BY 
			 Year_of_Release
			,Genre) tbl) tbl2) tbl3
Group BY 
 Year_of_Release

 )




/******************
 *** Main Query ***
 ******************/

SELECT 
 V.Year_of_Release
,V.Genre
FROM video_games V
INNER JOIN (SELECT TOP 1
			Year_of_Release
			FROM Peak_Genres_Per_Year_CTE 
			ORDER BY Num_Of_Peak_Genres DESC) tbl1
ON V.Year_of_Release=tbl1.Year_of_Release 
GROUP BY 
 V.Year_of_Release
,V.Genre


/** Question 3:
Calculate the weighted average, normal Average, and the mode of critic_score per
rating. Please present all numbers rounded with 1 decimal point. 
Which two ratings have the same values for all three measures? Please explain why **/


/** Answer 3: **/

WITH NrmlAverage_CTE AS (

SELECT 
 Rating
,ROUND((Critic_Score_Sum/Scores_Amount_Per_Rating),1) AS Normal_Average
FROM
-->tbl2
	(SELECT 
	 V.Rating
	,tbl.Scores_Amount_Per_Rating
	,SUM(V.Critic_Score) AS Critic_Score_Sum
	FROM video_games V
	INNER JOIN 
	-->>tbl
		(SELECT 
		 Rating
		,COUNT(Rating) AS Scores_Amount_Per_Rating
		FROM video_games
		WHERE Critic_Score IS NOT NULL AND Rating IS NOT NULL
		GROUP BY 
		 Rating) tbl
	ON V.Rating=tbl.Rating
	WHERE V.Critic_Score IS NOT NULL AND V.Rating IS NOT NULL
	GROUP BY 
	 V.Rating
	,tbl.Scores_Amount_Per_Rating) tbl2

)



,Weighted_Avg_CTE AS (

SELECT 
 Rating
,ROUND((Sum_Count_Value/Sum_Critic_Count),1) AS Weighted_Average
FROM
 -->>tbl1
	(SELECT 
	 Rating
	,SUM(Critic_Count) AS Sum_Critic_Count
	,SUM(Score_Count_Value) AS Sum_Count_Value
	FROM
	-->>tbl
		(SELECT 
		 Rating
		,Critic_Count
		,Critic_Score*Critic_Count AS Score_Count_Value
		FROM video_games
		WHERE Critic_Score IS NOT NULL AND Rating IS NOT NULL) tbl
	GROUP BY 
	Rating) tbl1

)



,Mode_CTE AS (

SELECT 
 Rating
,Critic_Score AS Critic_Score_Mode
FROM
-->>tbl1
	(SELECT 
	 Rating
	,Critic_Score
	,Count_Scores
	,ROW_NUMBER() OVER (PARTITION BY Rating ORDER BY count_Scores DESC) AS Count_Score_RNK
	FROM
	-->>tbl
		(SELECT 
		 Rating
		,Critic_Score
		,COUNT(Critic_Score) AS Count_Scores
		FROM video_games
		WHERE Critic_Score IS NOT NULL AND Rating IS NOT NULL
		GROUP BY 
		 Rating
		,Critic_Score) tbl) tbl1
WHERE Count_Score_RNK = 1


)




/******************
 *** Main Query ***
 ******************/

SELECT 
 N.rating
,N.Normal_Average
,W.weighted_Average
,M.Critic_Score_Mode
FROM NrmlAverage_CTE N
INNER JOIN Weighted_Avg_CTE W ON N.rating=W.rating
INNER JOIN Mode_CTE M ON N.rating=M.rating



/** Question 4:
Please provide the global sales by genre, Platform, and Year. **/


/** Answer 4: **/


WITH Years_CTE AS (

SELECT 
 DISTINCT Year_of_Release
FROM video_games
WHERE Year_of_Release IS NOT NULL

)


,Genre_CTE AS (

SELECT 
 DISTINCT Genre
FROM video_games
WHERE Genre IS NOT NULL

)



,Platform_CTE AS (

SELECT 
 DISTINCT Platform
FROM video_games
WHERE Platform IS NOT NULL

)



/******************
 *** Main Query ***
 ******************/

SELECT 
 tbl.Platform
,tbl.Year_of_Release
,tbl.Genre
,ISNULL(V.Global_Sales,0) AS Global_Sales
FROM
-->>tbl
	 (SELECT *
	  FROM Years_CTE
	  CROSS JOIN Genre_CTE, Platform_CTE) tbl
LEFT JOIN video_games V
ON tbl.Year_of_Release=V.Year_of_Release AND tbl.Genre=V.Genre AND tbl.Platform=V.Platform
ORDER BY 1,2,3


/** Question 5:
Analyze per platform the year with the highest YoY % (Year of Year relative growth
equation &gt; (a – b) / b), in terms of Global_Sales. 
Which of the following had recorded the most significant growth rate within the
dataset, and in which year? Circle the answer and write the year next to the icon. **/


/** Answer 5: **/

WITH Platform_CTE AS (

SELECT 
 DISTINCT Platform
FROM video_games
WHERE PLATFORM IS NOT NULL

)




,Year_CTE AS (

SELECT 
 DISTINCT Year_of_Release
FROM video_games
WHERE Year_of_Release IS NOT NULL AND Year_of_Release <> 2020

)




,Sales_Per_Year_Platform_CTE AS (


SELECT 
 tbl2.Platform
,tbl2.Year_of_Release
,SUM(tbl2.Global_Sales) AS Sum_Global_Sales
FROM 
-->>tbl2
	(SELECT 
	 tbl.Platform
	,tbl.Year_of_Release
	,ISNULL(V.Global_Sales,0) AS Global_Sales
	FROM 
	-->>tbl
		(SELECT *
		FROM Platform_CTE
		CROSS JOIN Year_CTE) tbl
	LEFT JOIN video_games V ON tbl.Platform=V.Platform AND tbl.Year_of_Release=V.Year_of_Release) tbl2
GROUP BY 
 tbl2.Platform
,tbl2.Year_of_Release

)



,YoY_CTE AS (

SELECT 
 Platform
,Year_of_Release AS Year
,Sum_Global_Sales
,CASE 
	WHEN LAG_1=0 THEN 0
	WHEN LAG_1<>0 THEN ROUND((((Sum_Global_Sales-LAG_1)/LAG_1)*100),0)
	END AS Year_Over_Year_Growth_Percent
FROM 
(SELECT 
 Platform
,Year_of_Release
,Sum_Global_Sales 
,LAG(Sum_Global_Sales,1,0) OVER (PARTITION BY Platform ORDER BY Year_of_Release) AS LAG_1
FROM Sales_Per_Year_Platform_CTE) tbl

)



/******************
 *** Main Query ***
 ******************/

SELECT TOP 1 *
FROM YoY_CTE
ORDER BY 4 DESC 




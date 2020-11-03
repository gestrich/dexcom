#/bin/bash


curl -X POST \
'https://api.dexcom.com/v2/users/self/statistics?startDate=2020-11-02T13:05:00&endDate=2020-11-02T13:10:00' \
-H 'authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IlR3eThiT1B4MGRvU1JoRk9WbGRnQlh0SkpiVSIsImtpZCI6IlR3eThiT1B4MGRvU1JoRk9WbGRnQlh0SkpiVSJ9.eyJpc3MiOiJodHRwczovL3VhbTEuZGV4Y29tLmNvbS9pZGVudGl0eSIsImF1ZCI6Imh0dHBzOi8vdWFtMS5kZXhjb20uY29tL2lkZW50aXR5L3Jlc291cmNlcyIsImV4cCI6MTYwNDMzOTk2NCwibmJmIjoxNjA0MzMyNzY0LCJjbGllbnRfaWQiOiJYQjlXS2xwa05aWlc4WjRwWFNKVk9uOWZkcUxyemNJRCIsInNjb3BlIjpbIm9mZmxpbmVfYWNjZXNzIiwiZWd2IiwiY2FsaWJyYXRpb24iLCJkZXZpY2UiLCJzdGF0aXN0aWNzIiwiZXZlbnQiXSwic3ViIjoiM2I3MDZmYTItNjMyYy00OWUyLWIxYjMtMzlkNDhjNWU0NGJlIiwiYXV0aF90aW1lIjoiMTYwNDI0Njk1MiIsImlkcCI6Imlkc3J2IiwianRpIjoiZWQ5OWYxNTRlNjM3YmJkNDkyMjU4MjM5MDllMzY3ODciLCJjb3VudHJ5X2NvZGUiOiJVUyIsImFtciI6WyJwYXNzd29yZCJdfQ.OxAf6sK148zTTqktyufoFoiqsBXe2mGoSXtS7z8WR6g7hkkpuPV0m9fcUFHO5TdeLsqO3s_W5s904iIq5w-N1zyW_U4lua1ivgmKh1bz5lJmnWESO7f23itdA0-u8l0ql_rMVN4jcO6Kw-ImelsZXDm3hG77_jSP5gAoBkcQZISyZva-1Jm4mWQnpcKfildFquyqs1Rd-g977IFq-Xzxm2jnnM1EB8PWXOPD3dwqUwMmX4OwZv5u1mOZaR_3pVNySmiYp1QG5roxYVQ8ovG2FMaVLiHLqMz57dkW349_oAco8tcvC2KdZRRX4qv7vgkBHirOQcZp7wBU_RGadGVMFQ' \
-H 'content-type: application/json' \
-d '{ 
 "targetRanges":[
      {
         "name":"day",  
         "startTime":"07:00:00",
         "endTime":"22:00:00",
         "egvRanges":[
           {
             "name": "urgentLow",
             "bound": 55
           },
           {
             "name": "low",
             "bound": 70
           },
           {
             "name": "high",
             "bound": 180
           }
         ]
      },
      {
         "name":"night",
         "startTime":"22:00:00",
         "endTime":"07:00:00",
         "egvRanges":[
           {
             "name": "urgentLow",
             "bound": 55
           },
           {
             "name": "low",
             "bound": 80
           },
           {
             "name": "high",
             "bound": 200
           }
         ]
      }
   ]
}'

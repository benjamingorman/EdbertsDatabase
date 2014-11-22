module Handler.People.EditPerson where

import Import
import Handler.Utils
import Handler.Plugins
import Handler.People.PersonUtils()
--Used for parsing textual database ids
import Database.Persist.Sql (toSqlKey, fromSqlKey)
import Data.Text.Read (decimal)

getEditPersonR :: PersonId -> Handler Html
getEditPersonR pid = do
    maybePerson <- runDB $ get pid
    case maybePerson of 
        Nothing -> do
            setMessage "No person found with that ID."
            redirect HomeR
        Just person -> do
            allGroups    <- runDB $ selectList ([] :: [Filter PGroup]) []
            personGroups <- relations pid :: Handler [Entity PGroup]

            allQuals     <- runDB $ selectList ([] :: [Filter Qual])   []
            personQuals  <- relations pid :: Handler [Entity Qual]
            --this is interpolated in the julius file and used to set the default selected options
            let gender         = (toJSON . fromMaybe . personGender) person
            let nationality    = (toJSON . fromMaybe . personNationality) person
            let personGroupIds = jsonKeys personGroups
            let personQualIds  = jsonKeys personQuals

            defaultLayout $ do
                datePickerWidget
                chosenWidget
                $(widgetFile "People/edit-person") 

postEditPersonR :: PersonId -> Handler Html
postEditPersonR pid = do
    editedPerson <- runInputPost $ Person
        <$> ireq textField "First name"
        <*> ireq textField "Last name"
        <*> iopt dayField  "Birthday"      
        <*> iopt textField "Home number"  
        <*> iopt textField "Mobile number"
        <*> iopt textField "Email address"
        <*> iopt textField "Gender"      
        <*> iopt textField "Nationality"
    runDB $ replace pid editedPerson
    
    groupIds <- lookupPostParams "group_ids"
    runDB $ deleteWhere [PersonGroupRelationPerson ==. pid]    
    mapM_ (insertGroupRelation pid) groupIds

    qualIds <- lookupPostParams "qual_ids"
    runDB $ deleteWhere [PersonQualRelationPerson ==. pid]    
    mapM_ (insertQualRelation pid) qualIds

    setMessage "Person succesfully edited."
    redirect (PersonR pid)

insertGroupRelation :: PersonId -> Text -> Handler ()
insertGroupRelation _   ""       = return ()
insertGroupRelation pid textGid  = runDB $ do
    case decimal textGid of
        Left  _        -> return ()
        Right (gid, _) -> insert_ $ PersonGroupRelation pid (toSqlKey gid)

insertQualRelation :: PersonId -> Text -> Handler ()
insertQualRelation _   ""       = return ()
insertQualRelation pid textQid  = runDB $ do
    case decimal textQid of
        Left  _        -> return ()
        Right (qid, _) -> insert_ $ PersonQualRelation pid (toSqlKey qid)

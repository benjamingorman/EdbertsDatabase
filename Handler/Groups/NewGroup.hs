module Handler.Groups.NewGroup where

import Import
import Handler.Plugins

getNewGroupR :: Handler Html
getNewGroupR = do
    defaultLayout $ do
        clockPickerWidget
        $(widgetFile "Groups/new-group") 

postNewGroupR :: Handler ()
postNewGroupR = do
    pGroup <- runInputPost $ PGroup
        <$> ireq textField "name"
        <*> ireq textField "project"
        <*> iopt textField "meets_on_day"  
        <*> iopt timeField "meets_at_time"
    runDB $ insert_ pGroup
    setMessage "Group succesfully created!"
    redirect GroupsR
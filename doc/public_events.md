#Public Events API

##POST /public_events 

Create a public event for a particular user and application.

###Request
<table>
    <tr> 
        <th>params</th>
        <th>description</th>
    </tr>
    <tr>
        <td>access_token</td>
        <td>The secret access token for that specific user and application</td>
    </tr>
    <tr>
        <td>event</td>
        <td>JSON data for event</td>
    </tr>
</table>


##GET /get_events

Get all of the public events for a user by access token

###Request
<table>
    <tr> 
        <th>params</th>
        <th>description</th>
    </tr>
    <tr>
        <td>access_token</td>
        <td>The secret access token for the specific user and application</td>
    </tr>
</table>


##DELETE /public_events

Deletes a specific event for a user.

###Request
<table>
    <tr> 
        <th>params</th>
        <th>description</th>
    </tr>
    <tr>
        <td>access_token</td>
        <td>The secret access token for the specific user and application</td>
    </tr>    
    <tr>
        <td>id</td>
        <td>The id for the event to be deleted</td>
    </tr>
</table>

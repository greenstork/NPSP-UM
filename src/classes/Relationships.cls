/*
	Copyright (c) 2009, Salesforce.com Foundation
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
	
	* Redistributions of source code must retain the above copyright
	  notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright
	  notice, this list of conditions and the following disclaimer in the
	  documentation and/or other materials provided with the distribution.
	* Neither the name of the Salesforce.com Foundation nor the names of
	  its contributors may be used to endorse or promote products derived
  	  from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
	FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
	COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
	POSSIBILITY OF SUCH DAMAGE.
*/
public class Relationships {

/// <name> Relationships </name>
	/// <summary> Default Constructor </summary>
	public Relationships()
	{
	}

	/// <name> Relationships </name>
	/// <summary> Overloads the Relationships object constructor to handle Relationship processing </summary>
	/// <param name="Relationships"> Relationship objects that are being triggered </param>
	/// <param name="oldRelationships"> Relationships object values before trigger event </param>
	/// <param name="ta"> Trigger action that is occuring </param>
	public Relationships(Relationship__c[] Relationships, Relationship__c[] oldRelationships, Relationships_Utils.triggerAction ta) 
	{	
		// Relationship list for termination updates
		List<Relationship__c> origrelationships = new List<Relationship__c>();
		List<Relationship__c> relationshipsToCreate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToDelete = new List<Relationship__c>();
		List<Relationship__c> reciprocalsToUpdate = new List<Relationship__c>();
		
		Integer i = 0;			// processing counter		
		
		for(Relationship__c r : Relationships) 
		{
			// AFTER INSERT
			if (ta==Relationships_Utils.triggerAction.afterInsert) 
			{
				if (r.ReciprocalRelationship__c == null)
				{
					relationshipsToCreate.add(r);
				}
				if (r.ReciprocalRelationship__c != null)
				{
					reciprocalsToUpdate.add(r);
				}
			}
			
			// AFTER UPDATE
			if (ta==Relationships_Utils.triggerAction.afterUpdate) 
			{
				if (r.ReciprocalRelationship__c == oldRelationships[i].ReciprocalRelationship__c && r.RelatedContact__c != null)
				{
					relationshipsToUpdate.add(r);
					origRelationships.add(oldRelationships[i]);
				}
				if (r.RelatedContact__c == null)
				{
					relationshipsToDelete.add(r);
				}
			}

			// AFTER DELETE
			if (ta==Relationships_Utils.triggerAction.afterDelete) 
			{
				if (r.ReciprocalRelationship__c != null)
				{
					relationshipsToDelete.add(r);
				}
			}

			i += 1;
		}

		if (relationshipsToCreate.size() > 0 ) {
			createRelationship(relationshipsToCreate);
		}
		if (relationshipsToUpdate.size() > 0 ) {
			updateRelationship(relationshipsToUpdate, origRelationships);
		}
		if (reciprocalsToUpdate.size() > 0 ) {
			reciprocate(reciprocalsToUpdate);
		}
		if (relationshipsToUpdate.size() > 0 ) {
			updateRelationship(relationshipsToUpdate, origRelationships);
		}
		if (relationshipsToDelete.size() > 0 ) {
			deleteRelationship(relationshipsToDelete);
		}
	}


	/// <name> deleteRelationships </name>
	/// <summary> Deletes Reciprocal Relationships when a Relationship is deleted </summary>
	/// <param name="relationships">  </param>
	public static void deleteRelationship(Relationship__c[] relationships)
	{
		List<Id> relationshipsToDelete = new List<Id>();
		for(Relationship__c r : Relationships) 
		{
			if (r.ReciprocalRelationship__c != null)
			{
				relationshipsToDelete.add(r.ReciprocalRelationship__c);
			} else
			if (r.RelatedContact__c == null)
			{
				relationshipsToDelete.add(r.Id);
			}
		}
		if ( relationshipsToDelete.size() > 0 )
		{
			Database.DeleteResult[] lsr = Database.delete(relationshipsToDelete, false);
		}
		
	}

	/// <name> deleteEmptyRelationships </name>
	/// <summary> Deletes Relationships when a Contact is deleted </summary>
	/// <param name="contacts"> List of Contacts that were deleted </param>
	@future
	public static void deleteEmptyRelationships()
	{
		List<Relationship__c> relationshipsToDelete = new List<Relationship__c>();
		for (Relationship__c r : [Select Id from Relationship__c where RelatedContact__c = null])
		{
			relationshipsToDelete.add(r);
		}
		if ( relationshipsToDelete.size() > 0 )
		{
			Database.DeleteResult[] lsr = Database.delete(relationshipsToDelete, false);
		}
	}
	
	/// <name> reciprocate </name>
	/// <summary>  </summary>
	/// <param name="Relationships">  </param>
	public static void reciprocate(Relationship__c[] Relationships)
	{
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		for(Relationship__c r : Relationships) 
		{
			Relationship__c copy = new Relationship__c(Id=r.ReciprocalRelationship__c, ReciprocalRelationship__c=r.Id);
			relationshipsToUpdate.add(copy);
		}
		update relationshipsToUpdate;
	}
	
	/// <name> createRelationship </name>
	/// <summary> Inserts a new reciprocal Relationship After a relationship is Inserted</summary>
	/// <param name="Relationships">  </param>
	public static void createRelationship(Relationship__c[] Relationships)
	{
		List<Relationship__c> relationshipsToCreate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		for(Relationship__c r : Relationships) 
		{
			Relationship__c copy = new Relationship__c();
			copy.Contact__c = r.RelatedContact__c;
			copy.RelatedContact__c = r.Contact__c;
			copy.Status__c = r.Status__c;
			copy.Type__c = r.Type__c;
			copy.ReciprocalRelationship__c = r.Id;
			copy.Description__c = r.Description__c;
			relationshipsToCreate.add(copy);
		}

		insert relationshipsToCreate;

	}

	/// <name> updateRelationship </name>
	/// <summary> Updates the Status and/or Type of a relationship After its reciprocal has been updated </summary>
	/// <param name="Relationships">  </param>
	/// <param name="oldRelationships">  </param>
	public static void updateRelationship(Relationship__c[] Relationships, Relationship__c[] oldRelationships)
	{
		List<Relationship__c> relationshipsToCreate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		Integer counter = 0;											// processing counter		

		for(Relationship__c r : Relationships) 
		{
			//SWA 2009-05-13 removed a duplicate check for change to Status__c from this OR statement
			if ((r.Status__c != oldRelationships[counter].Status__c || r.Type__c != oldRelationships[counter].Type__c || r.Description__c != oldRelationships[counter].Description__c)&& r.ReciprocalRelationship__c != null)
			{
				Relationship__c copy = new Relationship__c(Id=r.ReciprocalRelationship__c);
				
				//SWA 2009-05-13 - only attempt to modify the Contact field if the Related Contact  has changed
				if(oldRelationships[counter].RelatedContact__c!=r.RelatedContact__c){
					copy.Contact__c = r.RelatedContact__c;
				}
				copy.Status__c = r.Status__c;
				copy.Type__c = r.Type__c;
				copy.Description__c = r.Description__c;
				relationshipsToUpdate.add(copy);
			}
			counter += 1;
		}
		update relationshipsToUpdate;
	}
}
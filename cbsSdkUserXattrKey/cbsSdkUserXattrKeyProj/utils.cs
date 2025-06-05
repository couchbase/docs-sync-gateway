// tag::sdk-add-user-xattr-key[]
using System;
using System.Threading.Tasks;
using Couchbase;
using Couchbase.KeyValue; // <.>

namespace examples
{

    class utils
    {
        static async Task utilstask(string[] args)
        {
            // Set scope - cluster, bucket and collection
            var cluster =
                    await Cluster.ConnectAsync(
                                    "couchbase://localhost",
                                    "Administrator",
                                    "password");

            var bucket = await cluster.BucketAsync("hotels");
            var collection = bucket.DefaultCollection();

            // Set required  user_xattr_key name and value
            var our_user_xattr_key_name = "channelXattr"; // <.>
            String[] channelXattrValue =
                { "channel1", "channel3", "useradmin" }; // <.>

            var ourDocumentType = "hotel";
            var documentKey = "";

            // Find our document and get its id
            var queryResult =
               await cluster.QueryAsync<dynamic>(
                   "select meta().id from `hotels`.`_default`.`_default` h where h.type = $1",
                        new Couchbase.Query.QueryOptions().Parameter(ourDocumentType)); // <.>
            await foreach (var row in queryResult)
            {
                documentKey = row.id;
                Console.WriteLine("Working with document id: {0} ",
                                    documentKey);
                await collection.MutateInAsync(
                        documentKey,
                        specs => specs.Remove(
                            path: our_user_xattr_key_name, // <.>
                                                           //value: channelXattrValue, //<.>
                            isXattr: true)); // <.>


            }
            Console.WriteLine("Completed Changes\n");
        }
    }
}
// end::sdk-add-user-xattr-key[]
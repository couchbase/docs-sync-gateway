// tag::sdk-add-user-xattr-key[]
using System;
using System.Threading.Tasks;
using Couchbase;
using Couchbase.KeyValue; // <.>


namespace examples
{

    class Program
    {
        static async Task Main(string[] args)
        {
            // Set scope - cluster, bucket and collection
            var cluster =
                    await Cluster.ConnectAsync(
                                    "couchbase://localhost",
                                    "Administrator",
                                    "password");



            var bucket = await cluster.BucketAsync("travel-sample");
            var collection = bucket.DefaultCollection();

            // Set required  user_xattr_key name and value
            var our_user_xattr_key_name = "channelXattr"; // <.>
            String[] channelXattrValue =
                {"channel1","channel3", "useradmin" }; // <.>

            var ourDocumentType = "hotel";
            var documentKey = "";

            // Find our documents and get their ids
            var queryResult =
               await cluster.QueryAsync<dynamic>(
                   "select meta().id from `travel-sample`.`_default`.`_default` h where h.type = $1",
                        new Couchbase.Query.QueryOptions().Parameter(ourDocumentType)); // <.>
            await foreach (var row in queryResult)
            {
                documentKey = row.id;
                Console.WriteLine("Working with document id: {0} ",
                                    documentKey);

                // Check if the document has an existing
                // user_xattr_key and update or insert new value
                var result =
                    await collection.LookupInAsync(
                            documentKey,
                            specs => specs.Exists(
                                path: our_user_xattr_key_name,
                                isXattr: true)
                            ); // <.>

                if (result.Exists(0))
                {
                    // Update xattr for retrieved Id
                    await collection.MutateInAsync(
                            documentKey,
                            specs => specs.Upsert(
                                path: our_user_xattr_key_name, // <.>
                                value: channelXattrValue, //<.>
                                isXattr: true)); // <.>

                    Console.Write("Updated Existing user_xattr_key: {0} to this value: {1}\n",
                        our_user_xattr_key_name,
                        string.Join(", ", channelXattrValue));

                }
                else
                {
                    // Insert xattr for retrieved id
                    await collection.MutateInAsync(
                            documentKey,
                            specs => specs.Insert(
                                path: our_user_xattr_key_name, // <.>
                                value: channelXattrValue, //<.>
                                isXattr: true)); // <.>

                    Console.Write("Inserted New user_xattr_key: {0} with value {1}\n",
                        our_user_xattr_key_name,
                        string.Join(", ", channelXattrValue));

                }

            }
            Console.WriteLine("Completed Changes\n");
        }
    }
}
// end::sdk-add-user-xattr-key[]

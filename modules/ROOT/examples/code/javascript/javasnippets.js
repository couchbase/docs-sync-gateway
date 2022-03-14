// tag::sync-function-using-xattr[]
function (doc, oldDoc, meta) { // <.>

  if (meta.xattrs.channelXattr === undefined) // <.>
    {
      console.log("no user_xattr_key defined")
      channel(null)
    } else {
      channel(meta.xattrs.channelXattr) // <.>



    }

  // Further processing as required ../

// end::sync-function-using-xattr[]

/*
// tag::sync-function-using-xattr-notation[]
<.> The meta parameter exposes the user defined user_xattr_key if defined. The item takes the name configured for the database
<.> Access the meta parameter object to check an xattr exists on this document
<.> Use the content of the xattr to define the `channels` setting for this document
// end::sync-function-using-xattr-notation[]
*/

}

